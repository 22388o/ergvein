{-# OPTIONS_GHC -Wall #-}
{-# LANGUAGE LambdaCase #-}

module Ergvein.Wallet.Widget.Balance(
    balanceWidget
  , fiatBalanceWidget
  , fiatRateWidget
  , balanceTitleWidget
  ) where

import Control.Lens
import Data.Fixed (Centi)
import Text.Printf

import Ergvein.Types.Currency (smallestUnitBTC)
import Ergvein.Types.Storage.Currency.Public.Btc
import Ergvein.Types.Utxo.Btc
import Ergvein.Wallet.Localize.Status
import Ergvein.Wallet.Monad
import Ergvein.Wallet.Settings
import Sepulcas.Text (Display(..))

import qualified Data.List as L
import qualified Data.Map.Strict as M
import qualified Data.Text as T

btcBalance :: MonadFront t m => m (Dynamic t Money)
btcBalance = do
  pubStorageD <- getPubStorageBtcD
  pure $ ffor pubStorageD $ \case
    Nothing -> Money BTC 0
    Just pubStorage -> let
      utxos = M.elems $ pubStorage ^. btcPubStorage'utxos
      in Money BTC $ L.foldl' helper 0 utxos
  where
    helper :: MoneyAmount -> BtcUtxoMeta -> MoneyAmount
    helper balance BtcUtxoMeta{btcUtxo'status = EUtxoSending _} = balance
    helper balance BtcUtxoMeta{..} = balance + btcUtxo'amount

balanceWidget :: MonadFront t m => Currency -> m (Dynamic t Money)
balanceWidget cur = case cur of
  BTC  -> btcBalance

-- Returns text with fiat balance
-- Left values indicate an error in obtaining the exchange rate
-- Nothing values indicate that the fiat balance display is disabled in the settings
fiatBalanceWidget :: MonadFront t m => Currency -> m (Dynamic t (Either ExchangeRatesError (Maybe Text)))
fiatBalanceWidget cur = case cur of
  BTC  -> btcFiatBalanceWidget

btcFiatBalanceWidget :: MonadFront t m => m (Dynamic t (Either ExchangeRatesError (Maybe Text)))
btcFiatBalanceWidget = do
  showFiatBalanceD <- getFiatBalanceSettings
  fmap join $ networkHoldDyn $ ffor showFiatBalanceD $ \case
    Nothing -> pure $ constDyn $ Right Nothing
    Just fiat -> do
      balD <- balanceWidget BTC
      mRateD <- getRateByFiatD BTC fiat
      let fiatBalD = ffor2 balD mRateD (showFiatBalance fiat)
      pure fiatBalD

showFiatBalance :: Fiat -> Money -> Maybe Centi -> Either ExchangeRatesError (Maybe Text)
showFiatBalance _ _ Nothing = Left ExchangeRatesUnavailable
showFiatBalance fiat balance (Just rate) = Right $ Just $ showMoneyRated balance rate <> " " <> showt fiat

-- Returns text with fiat rate
-- Left values indicate an error in obtaining the exchange rate
-- Nothing values indicate that the exchange rate display is disabled in the settings
fiatRateWidget :: MonadFront t m => Currency -> m (Dynamic t (Either ExchangeRatesError (Maybe Text)))
fiatRateWidget cur = case cur of
  BTC  -> btcFiatRateWidget

btcFiatRateWidget :: MonadFront t m => m (Dynamic t (Either ExchangeRatesError (Maybe Text)))
btcFiatRateWidget = do
  showFiatRateD <- getFiatRateSettings
  fmap join $ networkHoldDyn $ ffor showFiatRateD $ \case
    Nothing -> pure $ constDyn $ Right Nothing
    Just fiat -> do
      mRateD <- getRateByFiatD BTC fiat
      let fiatBalD = ffor mRateD (showFiatRate BTC fiat)
      pure fiatBalD

showFiatRate :: Currency -> Fiat -> Maybe Centi -> Either ExchangeRatesError (Maybe Text)
showFiatRate _ _ Nothing = Left ExchangeRatesUnavailable
showFiatRate BTC fiat (Just rate) =
  let resolution = fromIntegral ((10 ^ currencyResolution BTC) :: Integer)
      rateToSat = (resolution / realToFrac rate) :: Double
      rateText = T.pack $ printf "%.2f" rateToSat
  in Right $ Just $ "1 " <> showt fiat <> " ≈ " <> rateText <> " " <> display smallestUnitBTC <> ""

balanceTitleWidget :: MonadFront t m => Currency -> m (Dynamic t Text)
balanceTitleWidget cur = case cur of
  BTC  -> btcBalanceTitleWidget

-- Creates balance string in units specified in settings.
-- Example: "12.2 BTC".
btcBalanceTitleWidget :: MonadFront t m => m (Dynamic t Text)
btcBalanceTitleWidget = do
  bal <- balanceWidget BTC
  units <- getSettingsUnitBtc
  let titleVal = ffor bal (`showMoneyUnit` units)
      curSymbol = display units
      title = (\x -> x <> " " <> curSymbol) <$> titleVal
  pure title
