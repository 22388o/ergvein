-- {-# OPTIONS_GHC -Wunused-top-binds #-}
-- Turn on unused-top-binds (if it's off) to see which TH-generated lenses to export
-- Read the README.md to learn now to work with migrations
module Ergvein.Types.Storage.Public
  (
    PubStorage(..)
  -- * Export lenses
  , pubStorage'rootPubKey
  , pubStorage'currencyPubStorages
  , pubStorage'activeCurrencies
  , pubStorage'restoring
  , pubStorage'seedBackupRequired
  , pubStorage'pathPrefix
  , btcPubStorage
  ) where

import Control.Lens
import Data.SafeCopy
import Data.Serialize

import Ergvein.Types.Currency
import Ergvein.Types.Derive
import Ergvein.Types.Keys.Prim
import Ergvein.Types.Storage.Currency.Public

data PubStorage = PubStorage {
    _pubStorage'rootPubKey          :: !EgvRootXPubKey
  , _pubStorage'currencyPubStorages :: !CurrencyPubStorages
  , _pubStorage'activeCurrencies    :: [Currency]
  , _pubStorage'restoring           :: !Bool -- ^ Flag to track unfinished process of restoration
  , _pubStorage'seedBackupRequired  :: !Bool -- ^ Flag to track unfinished process of seed backup
  , _pubStorage'pathPrefix          :: !(Maybe DerivPrefix)
  } deriving (Eq, Show, Read)

instance SafeCopy PubStorage where
  version = 2
  putCopy PubStorage{..} = contain $ do
    put _pubStorage'rootPubKey
    safePut _pubStorage'currencyPubStorages
    safePut _pubStorage'activeCurrencies
    put _pubStorage'restoring
    put _pubStorage'seedBackupRequired
    put _pubStorage'pathPrefix
  getCopy = contain $ PubStorage <$> get <*> safeGet <*> safeGet <*> get <*> get <*> get
  -- kind = extension -- Put extension when 3 version is added

-- This instances is required only for the current version
makeLenses ''PubStorage

-- | Extract public storage for BTC
btcPubStorage :: Lens' PubStorage CurrencyPubStorage
btcPubStorage = pubStorage'currencyPubStorages . at BTC . non (error "btcPubStorage: not exsisting store!")

