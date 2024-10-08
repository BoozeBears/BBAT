import { Alchemy, Network } from "alchemy-sdk";
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

import * as fs from "fs";

const config = {
  apiKey: "demo", // Replace with your Alchemy API key.
  network: Network.ETH_MAINNET, // Replace with your network.
};

const boozeBearContract = '0x701b2E775a82dbF50bd80a22a0d32EB13Fb81825'

const alchemy = new Alchemy(config);


const getHolders = async (blockNumber: string) => {
  return await alchemy.nft.getOwnersForContract(boozeBearContract, {
    withTokenBalances: true,
    block: blockNumber,
  });
}


async function main() {
  const holders = await getHolders("20149297");

  let values = [];
  for (const holder of holders.owners) {
    for (const item of holder.tokenBalances) {
      values.push([holder.ownerAddress, item.tokenId]);
    }
  }

  const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
  fs.writeFileSync("merkle-tree.json", JSON.stringify(tree.dump()));

  fs.writeFileSync("merkle-root.json", JSON.stringify(tree.root));
  console.log('Merkle Root:', tree.root);

  let mintsTmp: {[key: string] : {owner: string, tokenIds: number[], proofs: string[][] }} = {};
  for (const value of values) {
    if (!mintsTmp.hasOwnProperty(value[0])) {
      mintsTmp[value[0]] = {owner: value[0], "proofs": [], "tokenIds": []};
    }
    mintsTmp[value[0]]["tokenIds"].push(parseInt(value[1]));
    mintsTmp[value[0]]["proofs"].push(tree.getProof(value));
  }

  let mints: {owner: string, tokenIds: number[], proofs: string[][] }[] = [];
  for (const [k, v] of Object.entries(mintsTmp)) {
    mints.push(v);
  }

  fs.writeFileSync("merkle-mints.json", JSON.stringify(mints));
}

main()
