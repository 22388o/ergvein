{-
  Core types for handling of a collection of node connections
-}
module Ergvein.Core.Node.Types
  ( ConnMap
  , JSON
  , NodeConn(..)
  , HostPort
  , NodeConnection(..)
  , CurrencyRep(..)
  , CurrencyTag(..)
  , BtcType(..)
  , NodeBtc
  , HasNode(..)
  , NodeStatus(..)
  , NodeReqG(..)
  , NodeRespG(..)
  , NodeMessage(..)
  , Host
  , Port
  , getAllConnByCurrency
  , nodeString
  , getNodeReqCurrency
  ) where

import Data.Aeson
import Data.Dependent.Map (DMap)
import Data.GADT.Compare
import Data.Map.Strict (Map)
import Data.Text (Text)
import Data.Time (NominalDiffTime)
import Data.Type.Equality
import Data.Word
import Ergvein.Text (showt)
import Ergvein.Types
import Network.Socket (SockAddr)
import Reflex

import qualified Data.Dependent.Map as DM

type JSON a = (FromJSON a, ToJSON a)

-- Type-to-value mapping
class CurrencyRep cur where
  curRep :: cur -> Currency

-- Type family for request and response
class (CurrencyRep cur) => HasNode cur where
  type NodeReq cur :: *
  type NodeResp cur :: *
  type NodeSpecific cur :: *

data NodeConnection t cur = NodeConnection {
  nodeconCurrency   :: !Currency
, nodeconUrl        :: !SockAddr
, nodeconOpensE     :: !(Event t ())
, nodeconCloseE     :: !(Event t ())
, nodeconRespE      :: !(Event t (NodeResp cur))
, nodeconExtra      :: !(NodeSpecific cur)
, nodeconIsUp       :: !(Dynamic t Bool)
, nodeconDoLog      :: !Bool
, nodeconHeight     :: !(Dynamic t (Maybe Word32))
}

data NodeStatus = NodeStatus {
  nodestatHeight :: !BlockHeight
, nodestatLat    :: !NominalDiffTime
} deriving (Show)

data BtcType = BtcType
type NodeBtc t = NodeConnection t BtcType

data NodeConn t = NodeConnBtc !(NodeBtc t)

-- | Type alias for a combination of hostname and port.
type HostPort = (Host, Port)

-- | Type alias for a hostname.
type Host = String

-- | Type alias for a port number.
type Port = Int

-- | Node string for logging
nodeString :: Currency -> SockAddr -> Text
nodeString cur url = "[" <> showt cur <> "]<" <> showt url <> ">: "

data NodeReqG
  = NodeReqBtc  (NodeReq BtcType)
data NodeRespG
  = NodeRespBtc  (NodeResp BtcType)

data NodeMessage
  = NodeMsgRestart
  | NodeMsgClose
  | NodeMsgReq NodeReqG

getNodeReqCurrency :: NodeReqG -> Currency
getNodeReqCurrency req = case req of
  NodeReqBtc  {} -> BTC

data CurrencyTag t a where
  BtcTag :: CurrencyTag t (NodeBtc t)

instance GEq (CurrencyTag t) where
  geq BtcTag  BtcTag  = Just Refl

instance GCompare (CurrencyTag t) where
  gcompare BtcTag   BtcTag  = GEQ

type ConnMap t = DMap (CurrencyTag t) (Map SockAddr)

getAllConnByCurrency :: Currency -> ConnMap t -> Maybe (Map SockAddr (NodeConn t))
getAllConnByCurrency cur cm = case cur of
  BTC  -> fmap NodeConnBtc <$> DM.lookup BtcTag cm
