"use client"

export const runtime = 'edge';

import { useAccount } from 'wagmi'

import FormControl from '@mui/material/FormControl';
import InputLabel from '@mui/material/InputLabel';
import Input from '@mui/material/Input';
import FormHelperText from '@mui/material/FormHelperText';
import Button from '@mui/material/Button';

export default function Home() {
  const account = useAccount();

  return (
    <FormControl>
      <InputLabel htmlFor="vault-address">Vault</InputLabel>
      <Input id="vault-address" aria-describedby="my-helper-text" />
      <FormHelperText id="vault-address">If using redirect, input token owner address</FormHelperText>
      <Button disabled={!account.isConnected}>Mint</Button>
    </FormControl>
  );
}
