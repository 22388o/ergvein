{-# OPTIONS_GHC -Wno-orphans #-}
module Ergvein.Wallet.Localize.Settings(
    SettingsPageStrings(..)
  , NetSetupStrings(..)
  , DeleteWalletStrings(..)
  ) where

import Data.Time
import Ergvein.Index.Protocol.Types
import Ergvein.Text
import Ergvein.Types.Currency
import Ergvein.Types.Transaction
import Sepulcas.Elements.Input.Class
import Ergvein.Wallet.Language
import Ergvein.Wallet.Localize.Input ()
import Ergvein.Wallet.Localize.IP

data SettingsPageStrings =
    STPSTitle
  | STPSButLanguage
  | STPSButActiveCurrs
  | STPSButNetwork
  | STPSButDisplay
  | STPSButPortfolio
  | STPSButMnemonicExport
  | STPSButDns
  | STPSButTor
  | STPSButNodes
  | STPSButSetPass
  | STPSButDeleteWallet
  | STPSButRbf
  | STPSEnableRbfByDefault
  | STPSSelectLanguage
  | STPSTorStatus
  | STPSTorEnable
  | STPSTorDisable
  | STPSTorEnabled
  | STPSTorDisabled
  | STPSUseTor
  | STPSSetsProxy
  | STPSProxyIpField
  | STPSProxyPortField
  | STPSSetsActiveCurrs
  | STPSSetsPortfolio
  | STPSSetsPortfolioEnable
  | STPSSetsFiatSelect
  | STPSSetsShowFiatBalance
  | STPSSetsShowFiatRate
  | STPSSelectUnitsFor Currency
  | STPSSetsPinOn
  | STPSSetsPinOff
  | STPSSetsPinInput
  | STPSSetsPinDoSet
  | STPSMnemonicExportMsg
  | STPSSuccess
  | STPSIPStrings IPStrings
  | STPSInputStrings InputStrings
  deriving (Eq, Show)

instance Wrappable IPStrings SettingsPageStrings where
  wrap = STPSIPStrings

instance Wrappable InputStrings SettingsPageStrings where
  wrap = STPSInputStrings

instance LocalizedPrint SettingsPageStrings where
  localizedShow l v = case l of
    English -> case v of
      STPSTitle               -> "Settings"
      STPSButLanguage         -> "Language"
      STPSButActiveCurrs      -> "Currencies"
      STPSButNetwork          -> "Network"
      STPSButDns              -> "DNS servers"
      STPSButTor              -> "Tor and proxy"
      STPSButNodes            -> "BTC nodes"
      STPSButSetPass          -> "Change password"
      STPSButDisplay          -> "Display"
      STPSButPortfolio        -> "Portfolio"
      STPSButMnemonicExport   -> "Export mnemonic phrase"
      STPSButDeleteWallet     -> "Delete wallet"
      STPSButRbf              -> "Replace by fee"
      STPSEnableRbfByDefault  -> "Send RBF enabled transactions by default:"
      STPSSelectLanguage      -> "Select language:"
      STPSTorStatus           -> "Current status"
      STPSTorEnable           -> "Enable"
      STPSTorDisable          -> "Disable"
      STPSTorEnabled          -> "Enabled:"
      STPSTorDisabled         -> "Disabled"
      STPSUseTor              -> "Use Tor"
      STPSSetsProxy           -> "SOCKS proxy configuration"
      STPSProxyIpField        -> "Proxy IP address"
      STPSProxyPortField      -> "Proxy port"
      STPSSetsActiveCurrs     -> "Settings for active currencies"
      STPSSetsPortfolio       -> "Settings for fiat and ticks"
      STPSSetsPortfolioEnable -> "Display portfolio"
      STPSSetsFiatSelect      -> "Fiat currency:"
      STPSSetsShowFiatBalance -> "Show fiat balance:"
      STPSSetsShowFiatRate    -> "Show rate:"
      STPSSelectUnitsFor cur  -> "Units to show " <> showt cur <> " amounts in:"
      STPSSetsPinOn           -> "Switch on PIN code"
      STPSSetsPinOff          -> "Switch off PIN code"
      STPSSetsPinInput        -> "Enter PIN code:"
      STPSSetsPinDoSet        -> "Set PIN code"
      STPSMnemonicExportMsg   -> "This is your password protected mnemonic phrase in QR code and text form. Choose the most convenient way."
      STPSSuccess             -> "Successfully updated settings"
      STPSIPStrings s         -> localizedShow English s
      STPSInputStrings s      -> localizedShow English s
    Russian -> case v of
      STPSTitle               -> "Настройки"
      STPSButLanguage         -> "Язык"
      STPSButActiveCurrs      -> "Валюты"
      STPSButNetwork          -> "Сеть"
      STPSButDns              -> "DNS сервера"
      STPSButTor              -> "Tor и прокси"
      STPSButNodes            -> "Ноды BTC"
      STPSButSetPass          -> "Изменить пароль"
      STPSButDisplay          -> "Отображение"
      STPSButPortfolio        -> "Портфель"
      STPSButMnemonicExport   -> "Экспортировать мнемоническую фразу"
      STPSButDeleteWallet     -> "Удалить кошелёк"
      STPSButRbf              -> "Replace by fee"
      STPSEnableRbfByDefault  -> "Отправлять RBF транзакции по умолчанию:"
      STPSSelectLanguage      -> "Выберите язык:"
      STPSTorStatus           -> "Статус подключения"
      STPSTorEnable          -> "Подключить"
      STPSTorDisable       -> "Отключить"
      STPSTorEnabled        -> "Подключено:"
      STPSTorDisabled     -> "Отключено"
      STPSUseTor              -> "Проксировать через Tor"
      STPSSetsProxy           -> "Настройки прокси SOCKS"
      STPSProxyIpField        -> "Адрес прокси"
      STPSProxyPortField      -> "Порт прокси"
      STPSSetsActiveCurrs     -> "Настройки активных валют"
      STPSSetsPortfolio       -> "Настройки отображения фиата и тиков"
      STPSSetsPortfolioEnable -> "Отображение портфеля"
      STPSSetsFiatSelect      -> "Фиатная валюта:"
      STPSSetsShowFiatBalance -> "Отображать фиатный баланс:"
      STPSSetsShowFiatRate    -> "Отображать курс:"
      STPSSelectUnitsFor cur  -> "Единицы отображения " <> showt cur <> ":"
      STPSSetsPinOn           -> "Включить ПИН код"
      STPSSetsPinOff          -> "Выключить ПИН код"
      STPSSetsPinInput        -> "Введите ПИН код:"
      STPSSetsPinDoSet        -> "Установить ПИН код"
      STPSMnemonicExportMsg   -> "Это ваша защищенная паролем мнемоническая фраза в виде QR-кода и в текстовом виде. Используйте наиболее подходящий для вас способ."
      STPSSuccess             -> "Настройки успешно обновлены"
      STPSIPStrings s         -> localizedShow Russian s
      STPSInputStrings s      -> localizedShow Russian s

instance LocalizedPrint UnitBTC where
  localizedShow _ v = case v of
    BtcWhole    -> "BTC"
    BtcMilli    -> "mBTC"
    BtcSat      -> "sat"

data NetSetupStrings
  = NSSTitle
  | NSSLatency NominalDiffTime
  | NSSIndexerHeight BlockHeight
  | NSSIndexerHeightAuth BlockHeight BlockHeight
  | NSSOffline
  | NSSWrongVersion (Maybe ProtocolVersion)
  | NSSMissingCurrencies
  | NSSNotSynced
  | NSSRefresh
  | NSSPing
  | NSSPingAll
  | NSSDisable
  | NSSEnable
  | NSSForget
  | NSSResolveConfDefault
  | NSSRestoreUrls
  | NSSRestoreDef
  | NSSReqTimeout
  | NSSActUrlNum
  | NSSReqNumMin
  | NSSReqNumMax
  | NSSSave
  | NSSAddUrl
  | NSSAddDns
  | NSSAdd
  | NSSDelete
  | NSSEdit
  | NSSCancel
  | NSSClose
  | NSSCopyURL
  | NSSFailedDns
  | NSSNoHeight

instance LocalizedPrint NetSetupStrings where
  localizedShow l v = case l of
    English -> case v of
      NSSTitle        -> "Network settings"
      NSSLatency lat  -> "Latency: " <> showt lat
      NSSIndexerHeight h -> "Height: " <> showt h
      NSSIndexerHeightAuth hb h -> "Height: " <> showt h <> "/" <> showt hb
      NSSOffline      -> "Offline"
      NSSWrongVersion ver -> "Indexer has incompatible version " <> maybe "" showt ver
      NSSMissingCurrencies -> "Indexer doesn't support all currencies"
      NSSNotSynced    -> "Indexer not fully synced"
      NSSRefresh      -> "Refresh"
      NSSPing         -> "Ping"
      NSSDisable      -> "Disable"
      NSSEnable       -> "Enable"
      NSSForget       -> "Forget"
      NSSPingAll      -> "Ping all"
      NSSResolveConfDefault -> "Using servers from system configuration"
      NSSRestoreUrls  -> "Restore default"
      NSSRestoreDef   -> "Restore default values"
      NSSReqTimeout   -> "Request timeout, s"
      NSSActUrlNum    -> "Min. number of active indexers"
      NSSReqNumMin    -> "Min. number of confirmations"
      NSSReqNumMax    -> "Required number of confirmations"
      NSSSave         -> "Save"
      NSSAddUrl       -> "Add indexer"
      NSSAddDns       -> "Add DNS"
      NSSAdd          -> "Add"
      NSSDelete       -> "Delete"
      NSSEdit         -> "Edit"
      NSSCancel       -> "Cancel"
      NSSClose        -> "Close"
      NSSCopyURL      -> "Copy URL"
      NSSFailedDns    -> "Failed to parse DNS IP"
      NSSNoHeight     -> "None"
    Russian -> case v of
      NSSTitle        -> "Настройки сети"
      NSSLatency lat  -> "Задержка: " <> showt lat
      NSSIndexerHeight h -> "Высота: " <> showt h
      NSSIndexerHeightAuth hb h -> "Высота: " <> showt h <> "/" <> showt hb
      NSSOffline      -> "Оффлайн"
      NSSWrongVersion ver -> "Индексатор несовместимой версии " <> maybe "" showt ver
      NSSMissingCurrencies -> "Индексатор не поддерживает все валюты"
      NSSNotSynced    -> "Не полностью синхронизирован"
      NSSRefresh      -> "Обновить"
      NSSPing         -> "Запросить статус"
      NSSDisable      -> "Отключить"
      NSSEnable       -> "Включить"
      NSSForget       -> "Забыть"
      NSSPingAll      -> "Запросить всех"
      NSSResolveConfDefault -> "Используем глобальные настройки системы"
      NSSRestoreUrls  -> "Сервера по умолчанию"
      NSSRestoreDef   -> "Значения по умолчанию"
      NSSReqTimeout   -> "Время ожидания ответа, с"
      NSSActUrlNum    -> "Минимальное количество активных серверов"
      NSSReqNumMin    -> "Минимальное количество подтверждений"
      NSSReqNumMax    -> "Необходимое количество подтверждений"
      NSSSave         -> "Сохранить"
      NSSAddUrl       -> "Добавить индексер"
      NSSAddDns       -> "Добавить DNS"
      NSSAdd          -> "Добавить"
      NSSDelete       -> "Удалить"
      NSSEdit         -> "Изменить"
      NSSCancel       -> "Отменить"
      NSSClose        -> "Закрыть"
      NSSCopyURL      -> "Copy URL"
      NSSFailedDns    -> "Некорректный IP DNS сервера"
      NSSNoHeight     -> "Нет"

data DeleteWalletStrings
  = DWSTitle
  | DWSWarn1
  | DWSBtnYes
  | DWSBtnPass
  | DWSBtnNo
  | DWSWarn2
  | DWSWarn2Desc
  | DWSWarn3
  | DWSFinStage
  | DWSFin

instance LocalizedPrint DeleteWalletStrings where
  localizedShow l v = case l of
    English -> case v of
      DWSTitle      -> "Delete wallet"
      DWSBtnYes     -> "Delete"
      DWSBtnPass    -> "Enter the password"
      DWSBtnNo      -> "Cancel"
      DWSWarn1      -> "Are you sure you want to delete this wallet?"
      DWSWarn2      -> "Do you have your mnemonic?"
      DWSWarn2Desc  -> "If you don't, you will lose access to all your money. Forever."
      DWSWarn3      -> "One last step. Enter the password to continue."
      DWSFinStage   -> "Okay, you have convinced me. Go on."
      DWSFin        -> "The wallet has been deleted. Redirecting."
    Russian -> case v of
      DWSTitle      -> "Удаление кошелька"
      DWSWarn1      -> "Вы уверены, что хотите удалить этот кошелёк?"
      DWSBtnYes     -> "Удалить"
      DWSBtnPass    -> "Ввести пароль"
      DWSBtnNo      -> "Отмена"
      DWSWarn2      -> "Сохранили ли вы мнемоническую фразу?"
      DWSWarn2Desc  -> "Без неё вы потеряете доступ к своим деньгам. Навсегда."
      DWSWarn3      -> "Последняя проверка. Введите пароль для подтверждения."
      DWSFinStage   -> "Окей, вы убедили меня. Можете удалять."
      DWSFin        -> "Кошелёк успешно удалён. Перенаправляю."
