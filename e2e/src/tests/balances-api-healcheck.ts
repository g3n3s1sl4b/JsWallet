import Axios from 'axios';
(async () => {
  const axiosConfig = {
    maxRedirects: 0,
    timeout: 10000,
    validateStatus: (status: number): boolean => status < 400,
    params: {
    },
  };
  const axios = Axios.create(axiosConfig);

  const bitcoreRequestURL = 'https://bitcore.testnet.velas.com/api/BTC/testnet/address/myVH5F64jS4gGvjoq4bMouuxQFLxEUmB8U/balance';
  const bitcoreResponse = await axios.get(bitcoreRequestURL);
  if (!bitcoreResponse.data.balance) throw new Error(`No balance returned from: ${bitcoreRequestURL}\nResponse data:\n${bitcoreResponse.data}`);

  const apiTestnetVelasURL = 'https://api.testnet.velas.com/rpc';
  const apiTestnetVelasResponse = await axios.post(apiTestnetVelasURL, {
    jsonrpc: "2.0",
    id: 1,
    method: "eth_getBalance",
    params: [
      "0x1201553d1cda7c3bd7abc037a382d958b2674528",
      "latest"
    ]
  });
  if (!apiTestnetVelasResponse.data) throw new Error(`Invalid response from: ${apiTestnetVelasURL}\nResponse data:\n${apiTestnetVelasResponse.data}`);

  const evmExplorerTestnetVelasURL = 'https://evmexplorer.testnet.velas.com/rpc';
  const evmExplorerTestnetVelasResponse = await axios.post(evmExplorerTestnetVelasURL, {
    jsonrpc: "2.0",
    id: 1,
    method: "eth_getBalance",
    params: [
      "0x1201553d1cda7c3bd7abc037a382d958b2674528",
      "latest"
    ]
  });
  if (!evmExplorerTestnetVelasResponse.data) throw new Error(`Invalid response from: ${evmExplorerTestnetVelasURL}\nResponse data:\n${evmExplorerTestnetVelasResponse.data}`);

  const explorerTestnetVelasURL = 'https://explorer.testnet.velas.com/rpc';
  const explorerTestnetVelasResponse = await axios.post(explorerTestnetVelasURL, {
    jsonrpc: "2.0",
    id: 1,
    method: "eth_getBalance",
    params: [
      "0x1201553d1cda7c3bd7abc037a382d958b2674528",
      "latest"
    ]
  });
  if (!explorerTestnetVelasResponse.data) throw new Error(`Invalid response from: ${explorerTestnetVelasURL}\nResponse data:\n${explorerTestnetVelasResponse.data}`);

  const infuraURL = 'https://ropsten.infura.io/v3/a0c2399264f646c687fffa45bf8a14c1';
  const infuraResponse = await axios.post(infuraURL, {
    jsonrpc: "2.0",
    id: 1,
    method: "eth_getBalance",
    params: [
      "0x9c525b0dbab6cef23ff3caf639e41e2d6cee857d",
      "latest"
    ]
  });
  if (!explorerTestnetVelasResponse.data) throw new Error(`Invalid response from: ${infuraURL}\nResponse data:\n${infuraResponse.data}`);
})();