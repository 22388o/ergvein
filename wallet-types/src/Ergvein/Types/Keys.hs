module Ergvein.Types.Keys (
    ScanKeyBox(..)
  , getLastUnusedKey
  , getPublicKeys
  , getExternalPublicKeys
  , getInternalPublicKeys
  , egvXPubCurrency
  , getExternalPubKeyIndex
  , extractXPubKeyFromEgv
  , getLabelFromEgvPubKey
  , unEgvXPrvKey
  , egvXPubKeyToEgvAddress
  , xPubToBtcAddr
  , extractAddrs
  , extractExternalAddrs
  , extractChangeAddrs
  -- * Reexport primary, non-versioned module
  , KeyPurpose(..)
  , EgvRootXPrvKey(..)
  , EgvXPrvKey(..)
  , EgvRootXPubKey(..)
  , EgvXPubKey(..)
  , xPubExport
  -- * Reexport latest version
  , EgvPubKeyBox(..)
  , PrvKeystore(..)
  , PubKeystore(..)
  -- * haskoin
  , XPrvKey(..)
  , XPubKey(..)
  ) where

import Data.Text              (Text)
import Data.Vector            (Vector)
import Ergvein.Crypto.Keys
import Ergvein.Types.Address
import Ergvein.Types.Currency
import Ergvein.Types.Keys.Box.Public (EgvPubKeyBox(..))
import Ergvein.Types.Keys.Prim
import Ergvein.Types.Keys.Store.Private (PrvKeystore(..))
import Ergvein.Types.Keys.Store.Public (PubKeystore(..))

import qualified Data.Set as S
import qualified Data.Vector as V

data ScanKeyBox = ScanKeyBox {
  scanBox'key     :: !EgvXPubKey
, scanBox'purpose :: !KeyPurpose
, scanBox'index   :: !Int
} deriving (Show)

-- ====================================================================
--      Utils
-- ====================================================================

unEgvXPrvKey :: EgvXPrvKey -> XPrvKey
unEgvXPrvKey key = case key of
  BtcXPrvKey k -> k

egvXPubCurrency :: EgvXPubKey -> Currency
egvXPubCurrency val = case val of
  BtcXPubKey{} -> BTC

getLastUnusedKey :: KeyPurpose -> PubKeystore -> Maybe (Int, EgvPubKeyBox)
getLastUnusedKey kp PubKeystore{..} = go Nothing vector
  where
    vector = case kp of
      Internal -> pubKeystore'internal
      External -> pubKeystore'external
    go :: Maybe (Int, EgvPubKeyBox) -> Vector EgvPubKeyBox -> Maybe (Int, EgvPubKeyBox)
    go mk vec = if V.null vec then mk else let
      kb@(EgvPubKeyBox _ txs m) = V.last vec
      in if m || not (S.null txs)
        then mk
        else go (Just (V.length vec - 1, kb)) $ V.init vec

-- | Get external public keys in storage.
getExternalPublicKeys :: PubKeystore -> Vector ScanKeyBox
getExternalPublicKeys PubKeystore{..} = V.imap (\i kb -> ScanKeyBox (pubKeyBox'key kb) External i) pubKeystore'external

-- | Get internal public keys in storage.
getInternalPublicKeys :: PubKeystore -> Vector ScanKeyBox
getInternalPublicKeys PubKeystore{..} = V.imap (\i kb -> ScanKeyBox (pubKeyBox'key kb) Internal i) pubKeystore'internal

-- | Get all public keys in storage (external and internal) to scan for new transactions for them.
getPublicKeys :: PubKeystore -> Vector ScanKeyBox
getPublicKeys pubKeyStore = ext <> int
  where
    ext = getExternalPublicKeys pubKeyStore
    int = getInternalPublicKeys pubKeyStore

getExternalPubKeyIndex :: PubKeystore -> Int
getExternalPubKeyIndex = V.length . pubKeystore'external

extractXPubKeyFromEgv :: EgvXPubKey -> XPubKey
extractXPubKeyFromEgv key = case key of
  BtcXPubKey k _ -> k

getLabelFromEgvPubKey :: EgvXPubKey -> Text
getLabelFromEgvPubKey key = case key of
  BtcXPubKey _ l -> l

xPubToBtcAddr :: XPubKey -> BtcAddress
xPubToBtcAddr key = pubKeyWitnessAddr $ wrapPubKey True (xPubKey key)


egvXPubKeyToEgvAddress :: EgvXPubKey -> EgvAddress
egvXPubKeyToEgvAddress key = case key of
  BtcXPubKey k _ -> BtcAddress $ xPubToBtcAddr k

-- | Extract addresses from keystore
extractAddrs :: PubKeystore -> Vector EgvAddress
extractAddrs pks = fmap (egvXPubKeyToEgvAddress . scanBox'key) $ getPublicKeys pks

-- | Extract external addresses from keystore
extractExternalAddrs :: PubKeystore -> Vector EgvAddress
extractExternalAddrs pks = fmap (egvXPubKeyToEgvAddress . scanBox'key) $ getExternalPublicKeys pks

-- | Extract internal (change) addresses from keystore
extractChangeAddrs :: PubKeystore -> Vector EgvAddress
extractChangeAddrs pks = fmap (egvXPubKeyToEgvAddress . scanBox'key) $ getInternalPublicKeys pks
