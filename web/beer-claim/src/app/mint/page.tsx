"use client"

//export const runtime = 'edge';

import {useAccount, useReadContracts, useWaitForTransactionReceipt, useWriteContract} from 'wagmi'

import FormControl from '@mui/material/FormControl';
import Button from '@mui/material/Button';
import tokenContract from "@/contract/token";
import Box from "@mui/material/Box";
import FormGroup from '@mui/material/FormGroup';
import Alert from '@mui/material/Alert';
import SendIcon from "@mui/icons-material/Send";
import delegateContract from "@/contract/delegate";
import React from "react";

import merkleTree from '@/merkle-tree/tree'
import LinearProgress from "@mui/material/LinearProgress";
import Link from "@mui/material/Link";
import Typography from "@mui/material/Typography";

export default function Mint() {

  const account = useAccount();

  const {data: hash, error: writeContractError, isPending, writeContract} = useWriteContract()
  const {error: waitForTransactionError, isLoading: isConfirming, isSuccess: isConfirmed} = useWaitForTransactionReceipt({
    hash,
  })

  const {
    data, error: readContractsError, isPending: readContractsIsPending
  } = useReadContracts({
    contracts: [{
      ...tokenContract, functionName: 'isMintActive',
    }, {
      ...delegateContract, functionName: 'getDelegationSenders', args: [account && account.address || "0x0"]
    }]
  })
  const [isMintActive, delegationSenders] = data || []

  const mint = () => {
    if (account) {
      let proofs: `0x${string}`[][] = []
      let tokenIds: bigint[] = []
      for (const [i, v] of merkleTree.entries()) {
        if (v[0] === account.address) {
          tokenIds.push(BigInt(parseInt(v[1])));
          const proof = merkleTree.getProof(i) as `0x${string}`[];
          proofs.push(proof);
        }
      }
      writeContract({
        ...tokenContract, functionName: 'mint', args: [proofs, tokenIds, "0x0000000000000000000000000000000000000000" as `0x${string}`],
      })
    }
  }

  const mintDelegated = (sender: `0x${string}`) => {
    let proofs: `0x${string}`[][] = []
    let tokenIds: bigint[] = []
    for (const [i, v] of merkleTree.entries()) {
      if (v[0] === sender) {
        tokenIds.push(BigInt(parseInt(v[1])));
        const proof = merkleTree.getProof(i) as `0x${string}`[];
        proofs.push(proof);
      }
    }
    writeContract({
      ...tokenContract, functionName: 'mint', args: [proofs, tokenIds, sender as `0x${string}`],
    })
  }


  return (<Box>
    <Box hidden={!writeContractError}>
      <Alert severity="error">
        <Typography>
          {writeContractError && writeContractError.name}: {writeContractError && writeContractError.message}
        </Typography>
        <Link target={"_blank"} href={account.chain?.blockExplorers?.default.url + "/tx/" + hash}>Minted</Link>
      </Alert>
    </Box>
    <Box hidden={!waitForTransactionError}>
      <Alert severity="error">
        <Typography>
        {waitForTransactionError && waitForTransactionError.name}: {waitForTransactionError && waitForTransactionError.message}
        </Typography>
        <Link target={"_blank"} href={account.chain?.blockExplorers?.default.url + "/tx/" + hash}>Failure during mint</Link>
      </Alert>
    </Box>
    <Box hidden={!isConfirming}>
      <Alert severity="info">
        <Link target={"_blank"} href={account.chain?.blockExplorers?.default.url + "/tx/" + hash}>Mint pending</Link>
      </Alert>
    </Box>
    <Box hidden={!isConfirmed}>
      <Alert severity="success">
        <Link target={"_blank"} href={account.chain?.blockExplorers?.default.url + "/tx/" + hash}>Mint successfully</Link>
      </Alert>
    </Box>
    <Box hidden={!isConfirming}>
      <LinearProgress/>
    </Box>
    <Box component="form" autoComplete="off">
      <FormGroup row={true} sx={{p: 3}}>
        <FormControl fullWidth>
          <Button disabled={!account.isConnected || isPending || !isMintActive}
                  variant="contained"
                  endIcon={<SendIcon/>}
                  onClick={() => mint()}
          >Mint</Button>
          {delegationSenders && delegationSenders.result && delegationSenders.result.map(delegationSender => (
            <Button key={delegationSender} disabled={!account.isConnected || isPending || !isMintActive}
                    variant="contained"
                    endIcon={<SendIcon/>}
                    onClick={() => mintDelegated(delegationSender)}
            >Mint for {delegationSender}</Button>))}
        </FormControl>
      </FormGroup>
    </Box>
  </Box>);
}
