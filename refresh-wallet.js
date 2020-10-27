// Generated by LiveScript 1.6.0
(function(){
  var calcWallet, loadAllTransactions, loadRates, ref$, run, task, refreshWallet;
  calcWallet = require('./calc-wallet.ls');
  loadAllTransactions = require('./transactions.ls').loadAllTransactions;
  loadRates = require('./load-rates.ls');
  ref$ = require('./workflow.ls'), run = ref$.run, task = ref$.task;
  refreshWallet = function(web3, store, cb){
    var task1, task2, task3;
    store.current.refreshing = true;
    task1 = task(function(cb){
      return loadRates(store, cb);
    });
    task2 = task(function(cb){
      return loadAllTransactions(store, web3, cb);
    });
    task3 = task(function(cb){
      return calcWallet(store, cb);
    });
    return run([
      {
        task1: task1,
        task2: task2
      }, task3
    ]).then(function(){
      store.current.refreshing = false;
      return cb(null);
    });
  };
  module.exports = refreshWallet;
}).call(this);
