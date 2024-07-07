"use client"

//export const runtime = 'edge';

import {useAccount, useWriteContract, useReadContracts, useWaitForTransactionReceipt} from 'wagmi'

import React, {useState, useEffect} from 'react';
import FormGroup from '@mui/material/FormGroup';
import FormControl from '@mui/material/FormControl';
import Button from '@mui/material/Button';
import TextField from '@mui/material/TextField';
import Box from "@mui/material/Box";
import SendIcon from "@mui/icons-material/Send";
import {DatePicker} from '@mui/x-date-pickers/DatePicker';
import {LocalizationProvider} from '@mui/x-date-pickers/LocalizationProvider';
import {AdapterDayjs} from '@mui/x-date-pickers/AdapterDayjs';
import dayjs, { Dayjs } from 'dayjs';

import tokenContract from "@/contract/token";
import LinearProgress from "@mui/material/LinearProgress";

export default function Admin() {
  const account = useAccount();
  const {data: hash, isPending: writeContractIsPending, writeContract} = useWriteContract()

  const { isLoading: isConfirming, isSuccess: isConfirmed } =
    useWaitForTransactionReceipt({
      hash,
    })

  const {
    data,
    error:readContractsError,
    isPending: readContractsIsPending
  } = useReadContracts({
    contracts: [{
      ...tokenContract, functionName: 'mintPhaseState'
    }, {
      ...tokenContract, functionName: 'mintSchedule'
    }, {
      ...tokenContract, functionName: 'burnPhaseState'
    }, {
      ...tokenContract, functionName: 'burnSchedule'
    }, {
      ...tokenContract, functionName: 'merkleRoot'
    }, {
      ...tokenContract, functionName: 'delegateContractAddress'
    }]
  })
  const [
    mintPhaseState,
    mintSchedule,
    burnPhaseState,
    burnSchedule,
    merkleRoot,
    delegateContractAddress,
  ] = data || []

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
  }

  const flipMintPhaseState = () => {
    writeContract({
      ...tokenContract, functionName: 'flipMintPhaseState',
    })
  }

  const flipBurnPhaseState = () => {
    writeContract({
      ...tokenContract, functionName: 'flipBurnPhaseState',
    })
  }

  const [mintStart, setMintStart] = useState<Dayjs | null>(dayjs.unix(0));
  const [mintEnd, setMintEnd] = useState<Dayjs | null>(dayjs.unix(0));

  useEffect(() => {
    if (mintSchedule) {
      setMintStart(dayjs.unix(Number(mintSchedule && mintSchedule.result && mintSchedule.result[0] || 0)));
      setMintEnd(dayjs.unix(Number(mintSchedule && mintSchedule.result && mintSchedule.result[1] || 0)));
    }
  }, [mintSchedule])

  const setMintSchedule = () => {
    if (mintStart && mintEnd) {
      writeContract({
        ...tokenContract, functionName: 'setMintSchedule', args:[BigInt(mintStart.unix()), BigInt(mintEnd.unix())],
      })
    }
  }

  const [burnStart, setBurnStart] = useState<Dayjs | null>(dayjs.unix(0));
  const [burnEnd, setBurnEnd] = useState<Dayjs | null>(dayjs.unix(0));

  useEffect(() => {
    if (burnSchedule) {
      setBurnStart(dayjs.unix(Number(burnSchedule && burnSchedule.result && burnSchedule.result[0] || 0)));
      setBurnEnd(dayjs.unix(Number(burnSchedule && burnSchedule.result && burnSchedule.result[1] || 0)));
    }
  }, [burnSchedule])

  const setBurnSchedule = () => {
    if (burnStart && burnEnd) {
      writeContract({
        ...tokenContract, functionName: 'setBurnSchedule', args:[BigInt(burnStart.unix()), BigInt(burnEnd.unix())],
      })
    }
  }

  const [merkleRootValue, setMerkleRootValue] = useState<`0x${string}`>(merkleRoot && merkleRoot.result || "" as `0x${string}`);
  const setMerkleRoot = () => {
    if (merkleRootValue) {
      writeContract({
        ...tokenContract, functionName: 'setMerkleRoot', args:[merkleRootValue],
      })
    }
  }

  const [delegateContractAddressValue, setDelegateContractAddressValue] = useState<`0x${string}`>(delegateContractAddress && delegateContractAddress.result || "" as `0x${string}`);
  const setDelegateContractAddress = () => {
    if (delegateContractAddressValue) {
      writeContract({
        ...tokenContract, functionName: 'setDelegateContractAddress', args:[delegateContractAddressValue],
      })
    }
  }

  return (<Box component="form" autoComplete="off">
    <Box hidden={!isConfirming}>
      <LinearProgress/>
    </Box>
    <LocalizationProvider dateAdapter={AdapterDayjs}>
      <FormGroup row={false} sx={{p: 3}}>
        <FormControl disabled={!account.isConnected || readContractsIsPending || writeContractIsPending || isConfirming}>
          <Button variant="contained" onClick={flipMintPhaseState}>{`${mintPhaseState && mintPhaseState.result ? 'Disable Mint Phase' : 'Enable Mint Phase'}`}</Button>
          <Button variant="contained" onClick={flipBurnPhaseState}>{`${burnPhaseState && burnPhaseState.result ? 'Disable Burn Phase' : 'Enable Burn Phase'}`}</Button>
        </FormControl>
      </FormGroup>
      <FormGroup row={false} sx={{p: 3}}>
        <FormControl disabled={!account.isConnected || readContractsIsPending || writeContractIsPending || isConfirming}>
          <DatePicker label={"Mint Start"} format="YYYY-MM-DD" value={mintStart} onChange={(newValue) => setMintStart(newValue)}/>
          <DatePicker label={"Mint Stop"} format="YYYY-MM-DD" value={mintEnd} onChange={(newValue) => setMintEnd(newValue)}/>
          <Button variant="contained" endIcon={<SendIcon/>} onClick={setMintSchedule}>Set Mint Schedule</Button>
        </FormControl>
      </FormGroup>
      <FormGroup row={false} sx={{p: 3}}>
        <FormControl disabled={!account.isConnected || readContractsIsPending || writeContractIsPending || isConfirming}>
          <DatePicker label={"Burn Start"} format="YYYY-MM-DD" value={burnStart} onChange={(newValue) => setBurnStart(newValue)}/>
          <DatePicker label={"Burn Stop"} format="YYYY-MM-DD" value={burnEnd} onChange={(newValue) => setBurnEnd(newValue)}/>
          <Button variant="contained" endIcon={<SendIcon/>} onClick={setBurnSchedule}>Set Burn Schedule</Button>
        </FormControl>
      </FormGroup>
      <FormGroup row={false} sx={{p: 3}}>
        <FormControl disabled={!account.isConnected || readContractsIsPending || writeContractIsPending || isConfirming}>
          <TextField label={"Merkle Root"} value={merkleRootValue} onChange={(event) => setMerkleRootValue(event.target.value as `0x${string}`)}/>
          <Button variant="contained" endIcon={<SendIcon/>} onClick={setMerkleRoot}>Set Merkle Root</Button>
        </FormControl>
      </FormGroup>
      <FormGroup row={false} sx={{p: 3}}>
        <FormControl disabled={!account.isConnected || readContractsIsPending || writeContractIsPending || isConfirming}>
          <TextField label={"Delegation Contract"} value={delegateContractAddressValue} onChange={(event) => setDelegateContractAddressValue(event.target.value as `0x${string}`)}/>
          <Button variant="contained" endIcon={<SendIcon/>} onClick={setDelegateContractAddress}>Set Delegation Contract</Button>
        </FormControl>
      </FormGroup>
    </LocalizationProvider>
  </Box>);
}
