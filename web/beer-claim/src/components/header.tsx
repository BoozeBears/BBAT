import AppBar from '@mui/material/AppBar';
import Toolbar from '@mui/material/Toolbar';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Connect from '@/components/connect';
import Link from 'next/link'
import { usePathname } from 'next/navigation'

export default function Header() {
  const pathname = usePathname()

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
        </Box>
        <Connect/>
      </Toolbar>
    </AppBar>
  )
}
