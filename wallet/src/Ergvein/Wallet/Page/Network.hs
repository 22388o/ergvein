{-# LANGUAGE OverloadedLists #-}
module Ergvein.Wallet.Page.Network(
    networkPage
  ) where

import Reflex.ExternalRef

import Ergvein.Types.Currency
import Sepulcas.Elements
import Ergvein.Wallet.Language
import Ergvein.Wallet.Localize
import Ergvein.Wallet.Monad
import Ergvein.Wallet.Wrapper

import qualified Data.Dependent.Map as DM
import qualified Data.Map.Strict as M
import qualified Data.Set as S

networkPage :: MonadFront t m => Maybe Currency -> m ()
networkPage curMb = do
  title <- localized NPSTitle
  wrapper False title (Just $ pure $ networkPage curMb) $ do
    valD <- networkPageHeader curMb
    void $ networkHoldDyn $ ffor valD $ \case
      Nothing -> pure ()
      Just (cur, refrE) -> networkPageWidget cur refrE


networkPageWidget :: MonadFront t m => Currency -> Event t () -> m ()
networkPageWidget cur refrE = do
  lenlatD <- indexersAverageLatNumWidget refrE
  conmapD <- getNodeConnectionsD
  let (servNumD, avgLatD) = splitDynPure $ ffor lenlatD $ \(len, lat) -> let
        avgL = if len == 0 then NPSNoServerAvail else NPSAvgLat lat
        in (NPSServerVal len, avgL)
  listE <- lineOption $ do
    nameOption NPSServer
    listE <- el "div" $ do
      valueOptionDyn servNumD
      divClass "network-name-edit" $ fmap (cur <$) $ outlineButton NPSServerListView
    descrOption NPSServerDescr
    descrOptionDyn avgLatD
    labelHorSep
    pure listE
  -- lineOption $ lineOptionNoEdit NPSSyncStatus servCurInfoD NPSSyncDescr
  void $ lineOption $ networkHoldDyn $ ffor conmapD $ \cm -> case cur of
    BTC  -> btcNetworkWidget $ maybe [] M.elems $ DM.lookup BtcTag cm
  void $ nextWidget $ ffor listE $ \с -> Retractable {
      retractableNext = serversInfoPage с
    , retractablePrev = Just (pure $ networkPage (Just с))
    }
  pure ()

btcNetworkWidget :: MonadFront t m => [NodeBtc t] -> m ()
btcNetworkWidget nodes = do
  let activeND = fmap (length . filter id) $ sequence $ nodeconIsUp <$> nodes
  valueOptionDyn $ NPSActiveNum <$> activeND
  descrOption $ NPSNodesNum $ length nodes
  labelHorSep

networkPageHeader :: MonadFront t m => Maybe Currency -> m (Dynamic t (Maybe (Currency, Event t ())))
networkPageHeader minitCur = do
  activeCursD <- getActiveCursD
  resD <- fmap join $ titleWrap $ networkHoldDyn $ ffor activeCursD $ \curSet -> case S.toList curSet of
    [] -> do
      divClass "network-title-name" $ h3 $ localizedText NPSNoCurrencies
      pure $ pure $ Nothing
    cur:[] -> do
      divClass "network-title-name" $ h3 $ localizedText $ NPSTitleCur cur
      refrE <- divClass "network-title-cur" $ buttonClass "button button-outline net-refresh-btn" NPSRefresh
      pure $ pure $ Just (cur, refrE)
    curs -> do
      divClass "network-title-name" $ h3 $ localizedText $ NPSTitle
      curD <- divClass "network-title-cur" $ currenciesDropdown minitCur curs
      refrE <- divClass "network-title-cur" $ buttonClass "button button-outline net-refresh-btn" NPSRefresh
      pure $ (fmap . fmap) (, refrE) curD
  baseHorSep
  pure resD
  where
    titleWrap  = divClass "network-title-table" . divClass "network-title-row"
    baseHorSep = elAttr "hr" [("class","network-hr-sep"   )] blank
    currenciesDropdown :: MonadFrontBase t m => Maybe Currency -> [Currency] -> m (Dynamic t (Maybe Currency))
    currenciesDropdown minitKey currs = do
      langD <- getLanguage
      let listCursD = do
            l <- langD
            pure $ M.fromList $ fmap (\v -> (v, localizedShow l v)) currs
      let initKey = case minitKey of
            Nothing -> head currs
            Just k -> if k `elem` currs then k else head currs
      dp <- dropdown initKey listCursD $ def &
        dropdownConfig_attributes .~ constDyn ("class" =: "select-lang")
      (fmap . fmap) Just $ holdUniqDyn $ _dropdown_value dp

serversInfoPage :: MonadFront t m => Currency -> m ()
serversInfoPage initCur = do
  title <- localized NPSTitle
  wrapper False title (Just $ pure $ serversInfoPage initCur) $ mdo
    curD <- networkPageHeader $ Just initCur
    void $ networkHoldDyn $ ffor curD $ maybe (pure ()) $ \(_, refrE) -> do
      connsD  <- externalRefDynamic =<< getActiveConnsRef
      setsD  <- (fmap . fmap) S.toList $ externalRefDynamic =<< getActiveAddrsRef
      let valD = (,) <$> connsD <*> setsD
      void $ networkHoldDyn $ ffor valD $ \(conmap, urls) -> flip traverse urls $ \nsa -> do
        let mconn = M.lookup nsa conmap
        divClass "network-name" $ do
          let offclass = [("class", "mt-a mb-a indexer-offline")]
          let onclass = [("class", "mt-a mb-a indexer-online")]
          let maybe' m n j = maybe n j m
          let clsD = maybe' mconn (pure offclass) $ \con -> ffor (indexConIsUp con) $ \up -> if up then onclass else offclass
          elDynAttr "span" clsD $ elClass "i" "fas fa-circle" $ pure ()
          divClass "mt-a mb-a network-name-txt" $ text nsa
        case mconn of
          Nothing -> pure ()
          Just conn -> do
            latD <- indexerConnPingerWidget conn refrE
            descrOptionDynNoBR $ NPSLatency <$> latD
      pure ()

lineOption :: MonadFront t m => m a -> m a
lineOption = divClass "network-wrapper"

nameOption, descrOption :: (MonadFront t m, LocalizedPrint a) => a -> m ()
nameOption = divClass "network-name" . localizedText
descrOption = (>>) elBR . divClass "network-descr" . localizedText

valueOptionDyn, descrOptionDyn, descrOptionDynNoBR :: (MonadFront t m, LocalizedPrint a) => Dynamic t a -> m ()
valueOptionDyn v = getLanguage >>= \langD -> divClass "network-value" $ dynText $ ffor2 langD v localizedShow
descrOptionDyn v = getLanguage >>= \langD -> (>>) elBR (divClass "network-descr" $ dynText $ ffor2 langD v localizedShow)
descrOptionDynNoBR v = getLanguage >>= \langD -> divClass "network-descr" $ dynText $ ffor2 langD v localizedShow

labelHorSep, elBR :: MonadFront t m => m ()
labelHorSep = elAttr "hr" [("class","network-hr-sep-lb")] blank
elBR = el "br" blank
