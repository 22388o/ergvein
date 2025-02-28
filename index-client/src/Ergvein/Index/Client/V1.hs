module Ergvein.Index.Client.V1
  (
    HasClientManager(..)
  , getHeightEndpoint
  , getBlockFiltersEndpoint
  , pingEndpoint
  , getInfoEndpoint
  , getIntroducePeerEndpoint
  , getKnownPeersEndpoint
  , getFeeEstimatesEndpoint
  ) where

import Control.Monad.IO.Class
import Control.Monad.Reader
import Data.Proxy
import Network.HTTP.Client hiding (Proxy)
import Servant.API.Generic
import Servant.Client

import Ergvein.Index.API
import Ergvein.Index.API.Types
import Ergvein.Index.API.V1
import Ergvein.Text
import Ergvein.Types.Currency
import Ergvein.Types.Orphanage ()
import Sepulcas.Native

data AsClient

instance GenericMode AsClient where
  type AsClient :- api = Client ClientM api

api :: IndexVersionedApi AsClient
api = fromServant $ client (Proxy :: Proxy (ToServantApi IndexVersionedApi))

apiV1 :: IndexApi AsClient
apiV1 = fromServant $ indexVersionedApi'v1 api

class MonadIO m => HasClientManager m where
  getClientManager  :: m Manager

instance MonadIO m => HasClientManager (ReaderT Manager m) where
  getClientManager = ask

getHeightEndpoint :: (HasClientManager m, PlatformNatives) => BaseUrl -> HeightRequest -> m (Either ClientError HeightResponse)
getHeightEndpoint url req = do
  cenv <- (`mkClientEnv` url) <$> getClientManager
  res <- liftIO $ flip runClientM cenv $ indexGetHeight apiV1 req
  liftIO $ case res of
    Left er -> logWrite $ showt er
    _ -> pure ()
  pure res

getBlockFiltersEndpoint :: HasClientManager m => BaseUrl -> BlockFiltersRequest -> m (Either ClientError BlockFiltersResponse)
getBlockFiltersEndpoint url req = do
  cenv <- fmap (`mkClientEnv` url) getClientManager
  liftIO $ flip runClientM cenv $ indexGetBlockFilters apiV1 req

pingEndpoint :: HasClientManager m => BaseUrl -> () -> m (Either ClientError InfoResponse)
pingEndpoint url _ = do
  cenv <- fmap (`mkClientEnv` url) getClientManager
  liftIO $ flip runClientM cenv $ indexGetInfo apiV1

getInfoEndpoint :: HasClientManager m => BaseUrl -> () -> m (Either ClientError InfoResponse)
getInfoEndpoint url _ = do
  cenv <- fmap (`mkClientEnv` url) getClientManager
  liftIO $ flip runClientM cenv $ indexGetInfo apiV1

getIntroducePeerEndpoint :: HasClientManager m => BaseUrl -> IntroducePeerReq -> m (Either ClientError IntroducePeerResp)
getIntroducePeerEndpoint url req = do
  cenv <- fmap (`mkClientEnv` url) getClientManager
  liftIO $ flip runClientM cenv $ indexIntroducePeer apiV1 req

getKnownPeersEndpoint :: HasClientManager m => BaseUrl -> KnownPeersReq -> m (Either ClientError KnownPeersResp)
getKnownPeersEndpoint url req = do
  cenv <- fmap (`mkClientEnv` url) getClientManager
  liftIO $ flip runClientM cenv $ indexKnownPeers apiV1 req

getFeeEstimatesEndpoint :: HasClientManager m => BaseUrl -> [Currency] -> m (Either ClientError IndexFeesResp)
getFeeEstimatesEndpoint url curs = do
  cenv <- fmap (`mkClientEnv` url) getClientManager
  liftIO $ flip runClientM cenv $ indexGetFees apiV1 curs
