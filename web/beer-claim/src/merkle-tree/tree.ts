import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

const tree = {"format":"standard-v1","tree":["0x0fecce441c7468f17e3fe4a5f211b77a15b27c9ab3d33317df385dfbe5487034","0x636ab2686ee3036244cf3d6b5574e051e4b20a3577b008975dbcca6dde2897d2","0xd90245da324d7908326a3d56a9659741551a4603c397bf4dd373976bd85660e7","0x36fb17c97ec80bb961ff0adff1af4a2a34847ecc40653c162e327117a76e3ec9","0x1867c4ebd455913e429523a5c2d4b3a79f58068b5a25af911956245ed03a659d"],"values":[{"value":["0x80d628ff4AC2aFf620C3474663F1e559234bbE0c","0"],"treeIndex":4},{"value":["0x80d628ff4AC2aFf620C3474663F1e559234bbE0c","1"],"treeIndex":3},{"value":["0x80d628ff4AC2aFf620C3474663F1e559234bbE0c","2"],"treeIndex":2}],"leafEncoding":["address","uint256"]};

// @ts-ignore
const merkleTree = StandardMerkleTree.load(tree);

export default merkleTree;
