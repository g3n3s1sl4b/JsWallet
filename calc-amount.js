// Generated by LiveScript 1.6.0
(function(){
  var ref$, times, minus, plus, div, toJS, transaction, calcFee, find, round5, calcCryptoGeneric, calcCryptoFromUsd, calcCryptoFromEur, calcFiat, calcUsd, calcEur, calcFeeProxy, changeAmountGeneric, changeAmount, changeAmountInvoice, out$ = typeof exports != 'undefined' && exports || this;
  ref$ = require('./math.ls'), times = ref$.times, minus = ref$.minus, plus = ref$.plus, div = ref$.div;
  ref$ = require('mobx'), toJS = ref$.toJS, transaction = ref$.transaction;
  calcFee = require('./api.ls').calcFee;
  find = require('prelude-ls').find;
  round5 = require('./round5.ls');
  calcCryptoGeneric = function(name){
    return function(store, val){
      var send, wallet, token, rate, ref$;
      if (val == null) {
        return '0';
      }
      send = store.current.send;
      wallet = send.wallet;
      token = send.coin.token;
      rate = (ref$ = wallet != null ? wallet[name] : void 8) != null ? ref$ : 0;
      return round5(div(val, rate));
    };
  };
  out$.calcCryptoFromUsd = calcCryptoFromUsd = calcCryptoGeneric('usdRate');
  out$.calcCryptoFromEur = calcCryptoFromEur = calcCryptoGeneric('eurRate');
  calcFiat = function(name){
    return function(store, amountSend){
      var send, wallet, token, rate, ref$;
      if (amountSend == null) {
        return '0';
      }
      send = store.current.send;
      wallet = send.wallet;
      token = send.coin.token;
      rate = (ref$ = wallet != null ? wallet[name] : void 8) != null ? ref$ : 0;
      return times(amountSend, rate);
    };
  };
  out$.calcUsd = calcUsd = calcFiat('usdRate');
  out$.calcEur = calcEur = calcFiat('eurRate');
  calcFeeProxy = function(input, cb){
    var fun;
    fun = function(){
      return calcFee(input, cb);
    };
    calcFeeProxy.timer = clearTimeout(calcFeeProxy.timer);
    return calcFeeProxy.timer = setTimeout(fun, 500);
  };
  changeAmountGeneric = function(field){
    return function(store, amountSend, fast, cb){
      var send, wallet, token, wallets, feeToken, ref$, feeWallet, resultAmountSend, feeType, txType, feeCustomAmount, usdRate, feeUsdRate, account, calcFeeFun;
      send = store.current[field];
      wallet = send.wallet;
      token = send.coin.token;
      wallets = store.current.account.wallets;
      if (!send.to) {
        return cb(null);
      }
      feeToken = (ref$ = wallet.network.txFeeIn) != null
        ? ref$
        : (ref$ = send.coin.token) != null ? ref$ : 'unknown';
      feeWallet = find(function(it){
        var ref$;
        return ((ref$ = it.coin) != null ? ref$.token : void 8) === feeToken;
      })(
      wallets);
      if (wallet == null) {
        send.error = "Balance is not loaded";
      }
      if (wallet == null) {
        return cb("Balance is not loaded");
      }
      resultAmountSend = amountSend != null ? amountSend : 0;
      ref$ = store.current.send, feeType = ref$.feeType, txType = ref$.txType, feeCustomAmount = ref$.feeCustomAmount;
      usdRate = (ref$ = wallet != null ? wallet.usdRate : void 8) != null ? ref$ : 0;
      feeUsdRate = (ref$ = feeWallet != null ? feeWallet.usdRate : void 8) != null ? ref$ : 0;
      account = {
        address: wallet.address,
        privateKey: wallet.privateKey
      };
      send.amountSend = amountSend != null ? amountSend : "";
      send.amountSend = amountSend != null ? amountSend : "";
      send.value = times(resultAmountSend, Math.pow(10, send.network.decimals));
      send.amountObtain = resultAmountSend;
      send.amountObtainUsd = times(send.amountObtain, usdRate);
      send.amountSendUsd = calcUsd(store, amountSend);
      send.amountSendEur = calcEur(store, amountSend);
      calcFeeFun = fast ? calcFee : calcFeeProxy;
      return calcFeeFun({
        token: token,
        to: send.to,
        data: send.data,
        network: send.network,
        amount: resultAmountSend,
        feeType: feeType,
        txType: txType,
        account: account
      }, function(err, calcedFee){
        var ref$, txFee;
        if (err != null) {
          send.error = "Calc Fee Error: " + ((ref$ = err.message) != null ? ref$ : err);
        }
        if (err != null) {
          return cb("Calc Fee Error: " + ((ref$ = err.message) != null ? ref$ : err));
        }
        txFee = (function(){
          var ref$, ref1$;
          switch (false) {
          case calcedFee == null:
            return calcedFee;
          case ((ref$ = send.network) != null ? ref$.txFeeOptions : void 8) == null:
            return (ref1$ = send.network.txFeeOptions[feeType]) != null
              ? ref1$
              : send.network.txFee;
          default:
            return send.network.txFee;
          }
        }());
        send.amountSendFee = txFee;
        send.amountSendFeeOptions[feeType] = txFee;
        send.amountCharged = (function(){
          switch (false) {
          case (resultAmountSend != null ? resultAmountSend : "").length !== 0:
            return txFee;
          case resultAmountSend !== '0':
            return txFee;
          case resultAmountSend !== 0:
            return txFee;
          default:
            return plus(resultAmountSend, txFee);
          }
        }());
        send.amountChargedUsd = times(send.amountCharged, usdRate);
        send.amountSendFeeUsd = times(txFee, feeUsdRate);
        send.error = (function(){
          switch (false) {
          case wallet.balance !== '...':
            return "Balance is not yet loaded";
          case !(parseFloat(minus(wallet.balance, resultAmountSend)) < 0):
            return "Not Enough Funds";
          default:
            return "";
          }
        }());
        return cb(null);
      });
    };
  };
  out$.changeAmount = changeAmount = changeAmountGeneric('send');
  out$.changeAmountInvoice = changeAmountInvoice = changeAmountGeneric('invoice');
}).call(this);
