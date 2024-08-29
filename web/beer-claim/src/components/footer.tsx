import AppBar from '@mui/material/AppBar';
import Toolbar from '@mui/material/Toolbar';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Link from 'next/link'

export default function Footer() {
  const tokenContractAddress = process.env.NEXT_PUBLIC_TOKEN_CONTRACT_ADDRESS;
  const delegateContractAddress = process.env.NEXT_PUBLIC_DELEGATE_CONTRACT_ADDRESS;


  return (
    <AppBar position="fixed" color="primary" sx={{ top: 'auto', bottom: 0 }}>
      <Toolbar>
        <Box sx={{ flexGrow: 1 }}>
          <Link target={"_blank"} href={`https://amoy.polygonscan.com/address/${tokenContractAddress}`}>
            <Button>Token Contract</Button>
          </Link>
          <Link target={"_blank"} href={`https://amoy.polygonscan.com/address/${delegateContractAddress}`}>
            <Button>Delegate Contract</Button>
          </Link>
        </Box>
        <Box>Made by nexeck © 2024</Box>
      </Toolbar>
    </AppBar>
  )
}
