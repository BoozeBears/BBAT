import AppBar from '@mui/material/AppBar';
import Toolbar from '@mui/material/Toolbar';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Connect from '@/components/connect';
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import {useAccount, useReadContract} from "wagmi";
import tokenContract from "@/contract/token";

export default function Header() {
  const tokenContractAddress = process.env.NEXT_PUBLIC_TOKEN_CONTRACT_ADDRESS;
  const delegateContractAddress = process.env.NEXT_PUBLIC_DELEGATE_CONTRACT_ADDRESS;

  const pathname = usePathname()
  const account = useAccount();

  const {
    data: hasRoleAdmin, isPending: hasRoleAdminIsPending
  } = useReadContract({
    ...tokenContract, functionName: 'hasRole', args: ['0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775', account.address || "0x0"]
  })

  return (
    <AppBar component="nav">
      <Toolbar>
        <Box sx={{ flexGrow: 1 }}>
          <Link href="/">
            <Button key="home" variant={`${pathname === '/' ? 'contained' : 'outlined'}`}>Home</Button>
          </Link>
          <Link href="/mint">
            <Button key="mint" variant={`${pathname === '/mint' ? 'contained' : 'outlined'}`}>Mint</Button>
          </Link>
          <Link href="/delegate">
            <Button key="delegate" variant={`${pathname === '/delegate' ? 'contained' : 'outlined'}`}>Delegate</Button>
          </Link>
          <Link href="/admin" hidden={!hasRoleAdmin}>
            <Button key="admin" variant={`${pathname === '/admin' ? 'contained' : 'outlined'}`}>Admin</Button>
          </Link>
        </Box>
        <Box>
          <Link target={"_blank"} href={`https://amoy.polygonscan.com/address/${tokenContractAddress}`}>
            <Button>Token Contract</Button>
          </Link>
          <Link target={"_blank"} href={`https://amoy.polygonscan.com/address/${delegateContractAddress}`}>
            <Button>Delegate Contract</Button>
          </Link>
        </Box>
        <Connect/>
      </Toolbar>
    </AppBar>
  )
}
