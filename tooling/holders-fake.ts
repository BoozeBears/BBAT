import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import * as fs from "fs";

async function main() {
  let values = [];
  values.push(["0x80d628ff4AC2aFf620C3474663F1e559234bbE0c", "0"]);
  values.push(["0x80d628ff4AC2aFf620C3474663F1e559234bbE0c", "1"]);
  values.push(["0x80d628ff4AC2aFf620C3474663F1e559234bbE0c", "2"]);

  const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
  fs.writeFileSync("merkle-tree.json", JSON.stringify(tree.dump()));
  fs.writeFileSync("merkle-root.json", JSON.stringify(tree.root));

  console.log('Fake Merkle Root:', tree.root);
}

main()
