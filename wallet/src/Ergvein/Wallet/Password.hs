{-# OPTIONS_GHC -Wall #-}

module Ergvein.Wallet.Password(
    PasswordTries(..)
  , saveCounter
  , loadCounter
  , setupPassword
  , submitSetBtn
  , checkPasswordsMatch
  , setupLoginPassword
  , askTextPasswordWidget
  , askPasswordWidget
  , askPasswordModal
  , setupLogin
  , setupDerivPrefix
  , nameProposal
  , check
  ) where

import Control.Monad.Except
import Data.Either (fromRight)
import Data.List
import Data.Maybe
import Data.Time (getCurrentTime)
import Reflex.Localize.Dom

import Ergvein.Aeson
import Ergvein.Wallet.Localize
import Ergvein.Wallet.Monad
import Ergvein.Wallet.Page.PinCode
import Ergvein.Wallet.Wrapper
import Sepulcas.Elements
import Sepulcas.Validate

import qualified Data.Map.Strict as M
import qualified Data.Set as S
import qualified Data.Text as T

newtype PasswordTries = PasswordTries {
  passwordTriesCount  :: M.Map Text Integer
} deriving (Eq, Show)

$(deriveJSON (aesonOptionsStripPrefix "password") ''PasswordTries)

emptyPT :: PasswordTries
emptyPT = PasswordTries M.empty
{-# INLINE emptyPT #-}

saveCounter :: (MonadIO m, PlatformNatives, HasStoreDir m) => PasswordTries -> m ()
saveCounter pt = storeValue "tries.json" pt True

loadCounter :: (MonadIO m, PlatformNatives, HasStoreDir m) => m PasswordTries
loadCounter = fromRight emptyPT <$> retrieveValue "tries" emptyPT

-- | Helper to throw error when predicate is not 'True'
check :: MonadError a m => a -> Bool -> m ()
check a False = throwError a
check _ True = pure ()

submitSetBtn :: MonadFrontBase t m => m (Event t ())
submitSetBtn = submitClass "button button-outline" PWSSet

checkPasswordsMatch :: Reflex t => Event t () -> Dynamic t Text -> Dynamic t Text -> Event t ()
checkPasswordsMatch e d1 d2 = flip push e $ const $ do
  v1 <- sampleDyn d1
  v2 <- sampleDyn d2
  pure $ if v1 /= v2
    then Just ()
    else Nothing

setupPassword :: MonadFrontBase t m => Event t () -> m (Event t Password)
setupPassword e = divClass "setup-password" $ form $ fieldset $ mdo
  p1D <- passField PWSPassword noMatchE
  p2D <- passField PWSRepeat noMatchE
  let noMatchE = checkPasswordsMatch e p1D p2D
  validateEvent $ poke e $ const $ runExceptT $ do
    p1 <- sampleDyn p1D
    p2 <- sampleDyn p2D
    check PWSNoMatch $ p1 == p2
    pure p1

setupLoginPassword :: MonadFrontBase t m => Maybe Text -> Event t () -> m (Event t (Text, Password))
setupLoginPassword mlogin e = divClass "setup-password" $ form $ fieldset $ mdo
  existingWalletNames <- listStorages
  loginD <- labeledTextInput PWSLogin $ def
    & textInputConfig_initialValue .~ fromMaybe (nameProposal existingWalletNames) mlogin
    & textInputConfig_initialAttributes .~ ("placeholder" =: "my wallet name")
  p1D <- passField PWSPassword noMatchE
  p2D <- passField PWSRepeat noMatchE
  let noMatchE = checkPasswordsMatch e p1D p2D
  validateEvent $ poke e $ const $ runExceptT $ do
    p1 <- sampleDyn p1D
    p2 <- sampleDyn p2D
    l  <- sampleDyn loginD
    check PWSEmptyLogin $ not $ T.null l
    check PWSNoMatch $ p1 == p2
    pure (l,p1)

nameProposal :: [WalletName] -> WalletName
nameProposal s = let
  ss = S.fromList s
  in fromJust $ find (not . flip S.member ss) $ firstName : ((subsequentNamePrefix <>) . showt <$> [2 ::Int ..])
  where
   firstName = "main"
   subsequentNamePrefix = "wallet_"

setupLogin :: MonadFrontBase t m => Event t () -> m (Event t Text)
setupLogin e = divClass "setup-password" $ form $ fieldset $ mdo
  existingWalletNames <- listStorages
  loginD <- labeledTextInput PWSLogin $ def
    & textInputConfig_initialValue .~ nameProposal existingWalletNames
  validateEvent $ poke e $ const $ runExceptT $ do
    l <- sampleDyn loginD
    check PWSEmptyLogin $ not $ T.null l
    pure l

setupDerivPrefix :: MonadFrontBase t m => [Currency] -> Maybe DerivPrefix -> m (Dynamic t DerivPrefix)
setupDerivPrefix ac mpath = do
  divClass "password-setup-descr" $ h5 $ do
    localizedText PWSDerivDescr1
    br
    localizedText PWSDerivDescr2
  divClass "setup-password" $ form $ fieldset $ mdo
    let dval = fromMaybe defValue mpath
    pathTD <- labeledTextInput PWSDeriv $ def
      & textInputConfig_initialValue .~ showDerivPath dval
    pathE <- validateEvent $ ffor (updated pathTD) $ maybe (Left PWSInvalidPath) Right . parseDerivePath
    holdDyn dval pathE
  where
    defValue = case ac of
      [] -> defaultDerivePath BTC
      [c] -> defaultDerivePath c
      _ -> defaultDerivPathPrefix

askPasswordWidget :: MonadFrontBase t m => Text -> Bool -> Event t () -> m (Event t Password)
askPasswordWidget name writeMeta clearInputE
  | isAndroid = askPasswordAndroidWidget name writeMeta clearInputE
  | otherwise = askTextPasswordWidget PPSUnlock (PWSPassNamed name) clearInputE

askTextPasswordWidget :: (MonadFrontBase t m, LocalizedPrint l1, LocalizedPrint l2) => l1 -> l2 -> Event t () -> m (Event t Password)
askTextPasswordWidget title description clearInputE = divClass "my-a" $ do
  h4 $ localizedText title
  divClass "" $ do
    pD <- passField description clearInputE
    e <- submitClass "button button-outline" PWSGo
    pure $ tag (current pD) e

askPasswordAndroidWidget :: MonadFrontBase t m => Text -> Bool -> Event t () -> m (Event t Password)
askPasswordAndroidWidget name writeMeta clearInputE = mdo
  let fpath = "meta_wallet_" <> T.replace " " "_" name
  isPass <- fromRight False <$> retrieveValue fpath False
  passE <- if isPass
    then askPasswordImpl name writeMeta clearInputE
    else askPinCodeImpl name writeMeta clearInputE
  pure passE

askPasswordImpl :: MonadFrontBase t m => Text -> Bool -> Event t () -> m (Event t Password)
askPasswordImpl name writeMeta clearInputE = do
  let fpath = "meta_wallet_" <> T.replace " " "_" name
  when writeMeta $ storeValue fpath True True
  divClass "ask-password my-a" $ form $ fieldset $ do
    h4 $ localizedText PPSUnlock
    pD <- passField (PWSPassNamed name) clearInputE
    divClass "fit-content ml-a mr-a" $ do
      e <- divClass "" $ submitClass "button button-outline w-100" PWSGo
      pure $ tag (current pD) e

askPinCodeImpl :: MonadFrontBase t m => Text -> Bool -> Event t () -> m (Event t Password)
askPinCodeImpl name writeMeta clearInputE = do
  let fpath = "meta_wallet_" <> T.replace " " "_" name
  when writeMeta $ storeValue fpath False True
  mdo
    c <- loadCounter
    let cInt = fromMaybe 0 $ M.lookup name (passwordTriesCount c)
    now <- liftIO getCurrentTime
    a <- clockLossy 1 now
    freezeD <- networkHold (pure False) $ ffor (updated a) $ \TickInfo{..} -> do
      cS <- sampleDyn counterD
      let cdTime = if cS < 5
            then 0
            else 30 * (2 ^ (cS - 5))
      if (cdTime - _tickInfo_n) > 0
      then do
        divClass "backcounter" $ text $ "You should wait " <> showt (cdTime - _tickInfo_n) <> " sec"
        pure True
      else
        pure False
    passE <- pinCodeAskWidget clearInputE PinCodePSEnterPinCode
    counterD <- holdDyn cInt $ poke passE $ \_ -> do
      freezeS <- sampleDyn freezeD
      cS <- sampleDyn counterD
      if freezeS
        then pure cS
        else pure $ cS + 1
    performEvent_ $ ffor (updated counterD) $ \cS ->
      saveCounter $ PasswordTries $ M.insert name cS (passwordTriesCount c)
    pure $ attachPromptlyDynWithMaybe (\freeze p -> if not freeze then Just p else Nothing) freezeD passE

askPasswordModal :: MonadFront t m => m ()
askPasswordModal = mdo
  goE <- fmap fst getPasswordModalEF
  fire <- fmap snd getPasswordSetEF
  let redrawE = leftmost [Just <$> goE, Nothing <$ closeE]
  valD <- networkHold (pure (never, never)) $ ffor redrawE $ \case
    Just (i, passwordValidationResultE, name) -> divClass "ask-password-modal" $ do
      title <- localized PWSPassword
      let invalidPassE = fmapMaybe (\res -> if res == PasswordInvalid then Just () else Nothing) passwordValidationResultE
          validPassE = fmapMaybe (\res -> if res == PasswordValid then Just () else Nothing) passwordValidationResultE
      (closeBtnE, passE') <- wrapperPasswordModal title "password-widget-container" $
         askPasswordWidget name False invalidPassE
      let closeModalE = leftmost [closeBtnE, validPassE]
      pure ((i,) . Just <$> passE', closeModalE)
    Nothing -> pure (never, never)
  let (passD, closeD) = splitDynPure valD
      passE = switchDyn passD
      closeE = switchDyn closeD
  performEvent_ $ liftIO . fire <$> passE
