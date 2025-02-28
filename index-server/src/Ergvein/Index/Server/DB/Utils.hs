{-# LANGUAGE DeriveAnyClass #-}
module Ergvein.Index.Server.DB.Utils
  (
    unflatExact
  , decodeExact
  , unPrefixedKey
  , parsedKey
  , safeEntrySlice
  , getParsed
  , getParsedExact
  , getManyParsedExact
  , putItems
  , putItem
  , upsertItem
  ) where

import Control.Lens
import Control.Monad.IO.Class
import Control.Monad.Logger
import Data.ByteString (ByteString)
import Data.Default
import Data.Either
import Data.Serialize (Serialize)
import Data.Text
import Data.Time

import Ergvein.Index.Server.DB.Serialize.Class
import Ergvein.Index.Server.DB.Wrapper
import Ergvein.Types.Currency

import qualified Data.ByteString as BS
import qualified Data.Serialize as S
import qualified Data.Text as T
import qualified Database.LevelDB as LDB
import qualified Database.LevelDB.Streaming as LDBStreaming

unflatExact :: (EgvSerialize a) => Currency -> Text -> ByteString -> a
unflatExact cur t s = case egvDeserialize cur s of
    Right k -> k
    Left e -> error $ show t ++ show e ++ "value " ++  show (BS.unpack s)

decodeExact :: (Serialize b) => ByteString -> b
decodeExact s = case S.decode s of
    Right k -> k
    Left e -> error e

unPrefixedKey :: ByteString -> ByteString
unPrefixedKey = BS.tail

parsedKey :: Serialize k => ByteString -> k
parsedKey = fromRight (error "ser") . S.decode . unPrefixedKey

safeEntrySlice :: (EgvSerialize v, MonadIO m , Ord k, S.Serialize k) => Currency -> LevelDB -> BS.ByteString -> k -> k -> m [(k,v)]
safeEntrySlice cur db startKeyBinary startKey endKey = do
  slice <- streamSliceLDB db range LDBStreaming.Asc
  pure $ over _2 (unflatExact cur "safeEntrySlice")  <$> over _1 (decodeExact . unPrefixedKey) <$> slice
  where    
    range = LDBStreaming.KeyRange startKeyBinary comparison
    comparison key = case S.decode $ unPrefixedKey key of
      Right parsedK -> if startKey <= parsedK && parsedK <= endKey then LT else GT
      _ -> GT

getParsed :: (EgvSerialize v, MonadIO m) => Currency -> Text -> LevelDB -> BS.ByteString -> m (Maybe v)
getParsed cur c db key = do
  maybeResult <- getLDB db def key
  let caller = "getParsed: " <> c
  let maybeParsedResult = (unflatExact cur caller) <$> maybeResult
  pure maybeParsedResult

getParsedExact :: (EgvSerialize v, MonadIO m, MonadLogger m) => Currency -> Text -> LevelDB -> BS.ByteString -> m v
getParsedExact cur caller db key = do
  maybeResult <- getLDB db def key
  case maybeResult of
    Just result -> pure $ unflatExact cur caller result
    Nothing -> do
      currentTime <- liftIO getCurrentTime
      logErrorN $ "[Db read miss][getParsedExact]" <> "["<> caller <>"]"<> " Entity with key " <> (T.pack $ show key) <> " not found at time:" <> (T.pack $ show currentTime)
      error $ "getParsedExact: not found" ++ show key

getManyParsedExact :: (EgvSerialize v, MonadIO m, MonadLogger m) => Currency -> Text -> LevelDB -> [BS.ByteString] -> m [v]
getManyParsedExact cur caller db keys = traverse (getParsedExact cur caller db) keys

putItems :: (EgvSerialize v) => Currency -> (a -> BS.ByteString) -> (a -> v) -> [a] -> LDB.WriteBatch
putItems cur keySelector valueSelector items = putI <$> items
  where putI item = LDB.Put (keySelector item) $ egvSerialize cur $ valueSelector item

putItem :: (EgvSerialize v) => Currency -> BS.ByteString -> v -> LDB.WriteBatch
putItem cur key item = [LDB.Put key $ egvSerialize cur item]

upsertItem :: (EgvSerialize v, MonadIO m, MonadLogger m) => Currency -> LevelDB -> BS.ByteString -> v -> m ()
upsertItem cur db key item = do
  putLDB db def key $ egvSerialize cur item
