"use client"

export const runtime = 'edge';

import {useState} from "react";
import {useAccount, useReadContract, useWriteContract} from 'wagmi'

import FormControl from '@mui/material/FormControl';
import TextField from '@mui/material/TextField';
import Button from '@mui/material/Button';
import ButtonGroup from '@mui/material/ButtonGroup';
import Box from '@mui/material/Box';
import DeleteIcon from '@mui/icons-material/Delete';
import SendIcon from '@mui/icons-material/Send';

import abiDelegate from "@/abi/delegate";

export default function Delegate() {
  const delegateContractAddress = process.env.NEXT_PUBLIC_DELEGATE_CONTRACT_ADDRESS;

  const account = useAccount();
  const {data: hash, error, isPending, writeContract} = useWriteContract()


  const {
    data: delegateToAddress, error: getAllowanceReceiverError, isPending: getAllowanceReceiverIsPending
  } = useReadContract({
    abi: abiDelegate, address: delegateContractAddress as `0x${string}`, functionName: 'getAllowanceReceiver', args: [account.address as `0x${string}`, BigInt(0)],
  })

  let changeDelegation = function (delegateTo: `0x${string}`) {
    writeContract({
      abi: abiDelegate, address: delegateContractAddress as `0x${string}`, functionName: 'updateAllowanceReceiver', args: [delegateTo],
    })
  }

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    changeDelegation(hotAddress as `0x${string}`);
  }

  const [hotAddress, setHotAddress] = useState("")

  return (<form onSubmit={handleSubmit}>
    <Box component="form" autoComplete="off">
      <FormControl fullWidth required>
        <TextField
          id="hot-address"
          variant="filled"
          InputLabelProps={{shrink: true}}
          label={"Delegate To"}
          helperText={"Allow the following address to mint"}
          defaultValue={delegateToAddress?.toString()}
          onChange={e => setHotAddress(e.target.value)}
        />
        <ButtonGroup>
          <Button type={"reset"} disabled={!account.isConnected || getAllowanceReceiverIsPending} variant="outlined" startIcon={<DeleteIcon/>}>Reset</Button>
          <Button type={"submit"} disabled={!account.isConnected || getAllowanceReceiverIsPending} variant="contained" endIcon={<SendIcon/>}>Delegate</Button>
        </ButtonGroup>
      </FormControl>
    </Box>
  </form>);
}
