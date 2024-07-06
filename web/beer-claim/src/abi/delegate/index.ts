const abiDelegate = [{"inputs": [], "stateMutability": "nonpayable", "type": "constructor"}, {
  "inputs": [{
    "internalType": "address",
    "name": "owner",
    "type": "address"
  }, {"internalType": "uint256", "name": "tokenId", "type": "uint256"}],
  "name": "getAllowanceReceiver",
  "outputs": [{"internalType": "address", "name": "", "type": "address"}],
  "stateMutability": "view",
  "type": "function"
}, {"inputs": [], "name": "resetAllowanceReceiver", "outputs": [], "stateMutability": "nonpayable", "type": "function"}, {
  "inputs": [{
    "internalType": "uint256[]",
    "name": "tokenIds",
    "type": "uint256[]"
  }], "name": "resetAllowanceReceiver", "outputs": [], "stateMutability": "nonpayable", "type": "function"
}, {
  "inputs": [{"internalType": "uint256[]", "name": "tokenIds", "type": "uint256[]"}, {"internalType": "address", "name": "receiver", "type": "address"}],
  "name": "updateAllowanceReceiver",
  "outputs": [],
  "stateMutability": "nonpayable",
  "type": "function"
}, {
  "inputs": [{"internalType": "address", "name": "receiver", "type": "address"}],
  "name": "updateAllowanceReceiver",
  "outputs": [],
  "stateMutability": "nonpayable",
  "type": "function"
}]  as const;

export default abiDelegate;
