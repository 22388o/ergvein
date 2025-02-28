module Sepulcas.Android.Native(

  ) where

import Android.HaskellActivity
import Control.Exception (handle, bracket)
import Control.Monad
import Control.Monad.IO.Class
import Data.Text (Text)
import Data.Time (TimeZone(..))
import Ergvein.Aeson
import Foreign
import Foreign.C
import Sepulcas.Android.Native.Certs
import Sepulcas.Native
import System.Directory
import System.Directory.Tree
import System.FilePath.Posix
import System.IO
import System.X509.Android

import qualified Data.ByteString as BS
import qualified Data.Text as T
import qualified Data.Text.IO as T
import qualified Data.Text.Encoding as T

newtype JString = JString { unJString :: Ptr JString }

foreign import ccall safe "android_paste_str" androidPasteStr :: HaskellActivity -> IO JString
foreign import ccall safe "read_paste_str" androidReadPasteStr :: JString -> IO CString
foreign import ccall safe "release_paste_str" androidReleasePasteStr :: JString -> CString -> IO ()
foreign import ccall safe "android_copy_str" androidCopyStr :: HaskellActivity -> CString -> IO ()
foreign import ccall safe "android_log_write" androidLogWrite :: CString -> IO ()
foreign import ccall safe "android_timezone_offset" androidTimeZoneOffset :: IO Int
foreign import ccall safe "android_timezone_id" androidTimeZoneId :: IO CString
foreign import ccall safe "android_share_url" androidShareUrl :: HaskellActivity -> CString -> IO ()
foreign import ccall safe "android_open_url" androidOpenUrl :: HaskellActivity -> CString -> IO ()
foreign import ccall safe "android_camera_open" androidCameraOpen :: HaskellActivity -> CString -> IO ()
foreign import ccall safe "android_camera_get_result" androidCameraGetResult :: HaskellActivity -> IO CString
foreign import ccall safe "android_share_jpeg" androidShareJpeg :: HaskellActivity -> CString -> CString -> IO ()
foreign import ccall safe "android_detectdns" androidDetectDnsImpl :: HaskellActivity -> IO CString

decodeText :: CString -> IO Text
decodeText cstr = do
  bytestr <- BS.packCString cstr
  return (T.decodeUtf8 bytestr)

encodeText :: Text -> (CString -> IO a) -> IO a
encodeText text cont =
  BS.useAsCString (T.encodeUtf8 text) cont

instance PlatformNatives where
  currentPlatform = Android

  getHomeDir = do
    mdir <- liftIO $ getFilesDir =<< getHaskellActivity
    maybe (error "No home dir detected!") (pure . T.pack) mdir

  resUrl = (<>) "file:///android_res/"

  storeBS fname bs _ = do
    path <- getStoreDir
    logWrite $ "Writing ByteString to file " <> path <> "/" <> fname
    liftIO $ do
      let fpath = T.unpack $ path <> "/" <> fname
      createDirectoryIfMissing True $ takeDirectory fpath
      BS.writeFile fpath bs

  retrieveBS fname = do
    path <- getStoreDir
    logWrite $ "Reading ByteString from file " <> path <> "/" <> fname
    liftIO $ do
      let fpath = T.unpack $ path <> "/" <> fname
      ex <- doesFileExist fpath
      if ex
        then fmap Right $ BS.readFile fpath
        else pure $ Left $ NAFileDoesNotExist fname

  storeValue k v atomicMode = do
    path <- getStoreDir
    logWrite $ "Writing JSON to file " <> path <> "/" <> k
    liftIO $ do
      let fpath = T.unpack $ path <> "/" <> k
      createDirectoryIfMissing True $ takeDirectory fpath
      case atomicMode of
        True -> writeJsonAtomic fpath v
        False -> writeJson fpath v

  retrieveValue k a0 = do
    path <- getStoreDir
    logWrite $ "Reading JSON from file " <> path <> "/" <> k
    liftIO $ do
      let fpath = T.unpack $ path <> "/" <> k
      ex <- doesFileExist fpath
      if ex
        then do
          key <- readJson fpath
          pure $ maybe (Left $ NADecodingError k) Right key
        else pure $ Right a0

  listKeys = do
    path <- getStoreDir
    liftIO $ fmap (T.drop (T.length path + 1) . T.pack) <$> getFiles (T.unpack path)

  readStoredFile filename = do
    path <- getStoreDir
    logWrite $ "Reading file " <> path <> "/" <> filename
    liftIO $ do
      let fpath = T.unpack $ path <> "/" <> filename
      ex <- doesFileExist fpath
      if ex
        then do
          cnt <- T.readFile fpath
          pure $ Right $ T.lines cnt
        else pure $ Left $ NAFileDoesNotExist filename

  appendStoredFile filename cnt = do
    path <- getStoreDir
    logWrite $ "Appending file " <> path <> "/" <> filename
    liftIO $ do
      let fpath = T.unpack $ path <> "/" <> filename
      ex <- doesFileExist fpath
      if ex
        then T.appendFile fpath cnt
        else T.writeFile fpath cnt

  moveStoredFile filename1 filename2 = do
    path <- getStoreDir
    logWrite $ "Moving file " <> path <> "/" <> filename1 <> " to " <> path <> "/" <> filename2
    liftIO $ do
      let fpath1 = T.unpack $ path <> "/" <> filename1
          fpath2 = T.unpack $ path <> "/" <> filename2
      ex <- doesFileExist fpath1
      if ex
        then Right <$> renameFile fpath1 fpath2
        else pure $ Left $ NAFileDoesNotExist filename1

  deleteStoredFile filename = do
    path <- getStoreDir
    logWrite $ "Deleting file " <> path <> "/" <> filename
    liftIO $ do
      let fpath = T.unpack $ path <> "/" <> filename
      ex <- doesFileExist fpath
      when ex $ removeFile fpath

  getStoreFileSize filename = do
    path <- getStoreDir
    liftIO $ do
      let fpath = T.unpack $ path <> "/" <> filename
      ex <- doesFileExist fpath
      if ex
        then fmap Right $ withFile fpath ReadMode $ fmap fromIntegral . hFileSize
        else pure $ Left $ NAFileDoesNotExist filename

  pasteStr = liftIO $ do
    jstring <- androidPasteStr =<< getHaskellActivity
    bracket allocPaste releasePaste $ decodeText . snd
    where
      allocPaste = do
        a <- getHaskellActivity
        jstring <- androidPasteStr a
        cstr <- androidReadPasteStr jstring
        pure (jstring, cstr)
      releasePaste (jstring, cstr) = androidReleasePasteStr jstring cstr

  copyStr v = liftIO $ encodeText v $ \s -> do
    a <- getHaskellActivity
    androidCopyStr a s

  getTimeZone = liftIO $ do
    offset <- androidTimeZoneOffset
    id' <- androidTimeZoneId
    id <- decodeText id'
    pure $ TimeZone offset False (T.unpack id)

  shareUrl v = liftIO $ encodeText v $ \s -> do
    a <- getHaskellActivity
    androidShareUrl a s

  openUrl v = liftIO $ encodeText v $ \s -> do
    a <- getHaskellActivity
    androidOpenUrl a s

  cameraWork v = liftIO $ encodeText v $ \s -> do
    a <- getHaskellActivity
    androidCameraOpen a s

  cameraGetResult = liftIO $ do
    a <- getHaskellActivity
    r <- androidCameraGetResult a
    t <- decodeText r
    pure $ T.takeWhileEnd (/= ':') t

  logWrite v = liftIO $ encodeText v androidLogWrite
  {-# INLINE logWrite #-}

  readSystemCertificates = getSystemCertificateStore additionalCertificates

  nativeShareJpeg b64jpeg filename = liftIO $ encodeText b64jpeg $ \s -> encodeText filename $ \fs -> do
    a <- getHaskellActivity
    androidShareJpeg a s fs

  androidDetectDns = liftIO $ do
    a <- getHaskellActivity
    r <- androidDetectDnsImpl a
    t <- decodeText r
    pure $ fmap T.unpack $ T.splitOn ";" t

getFiles :: FilePath -> IO [FilePath]
getFiles dir = do
  _ :/ tree <- build dir
  pure $ reverse $ go tree
  where
    go tree = case tree of
      File _ n -> [n]
      Dir _ trees -> concat . fmap go $ trees
      _ -> []
