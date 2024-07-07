"use client"

//export const runtime = 'edge';

import {useState} from "react";
import {useAccount, useReadContract, useWaitForTransactionReceipt, useWriteContract} from 'wagmi';

import FormControl from '@mui/material/FormControl';
import TextField from '@mui/material/TextField';
import Button from '@mui/material/Button';
import ButtonGroup from '@mui/material/ButtonGroup';
import Box from '@mui/material/Box';
import DeleteIcon from '@mui/icons-material/Delete';
import SendIcon from '@mui/icons-material/Send';
import LinearProgress from '@mui/material/LinearProgress';

import delegateContract from "@/contract/delegate";

export default function Delegate() {

  const account = useAccount();
  const {data: hash, error: writeContractError, isPending: writeContractIsPending, writeContract} = useWriteContract()

  const {isLoading: isConfirming, isSuccess: isConfirmed} = useWaitForTransactionReceipt({
    hash,
  })

  const {
    data: delegateToAddress, error: getAllowanceReceiverError, isPending: getAllowanceReceiverIsPending
  } = useReadContract({
    ...delegateContract, functionName: 'getDelegationReceiver', args: [account.address as `0x${string}`],
  })

  let changeDelegation = function (delegateTo: `0x${string}`) {
    writeContract({
      ...delegateContract, functionName: 'setDelegation', args: [delegateTo],
    })
  }

  let resetDelegation = function () {
    writeContract({
      ...delegateContract, functionName: 'resetDelegation',
    })
  }

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    changeDelegation(hotAddress as `0x${string}`);
  }

  async function handleReset(e: React.FormEvent<HTMLFormElement>)  {
    e.preventDefault();
    resetDelegation();
  }

  const [hotAddress, setHotAddress] = useState("")

  return (<Box>
    <Box component="form" autoComplete="off" onSubmit={handleSubmit} onReset={handleReset}>
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
          <Button type={"reset"} disabled={!account.isConnected || getAllowanceReceiverIsPending || writeContractIsPending || isConfirming} variant="outlined"
                  startIcon={<DeleteIcon/>}>Reset</Button>
          <Button type={"submit"} disabled={!account.isConnected || getAllowanceReceiverIsPending || writeContractIsPending || isConfirming} variant="contained"
                  endIcon={<SendIcon/>}>Delegate</Button>
        </ButtonGroup>
      </FormControl>
    </Box>
    <Box hidden={!isConfirming}>
      <LinearProgress/>
    </Box>
  </Box>);
}
