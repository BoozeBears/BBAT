'use client';

import { AppRouterCacheProvider } from '@mui/material-nextjs/v14-appRouter';
import { ThemeProvider } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import theme from '@/theme';

import Web3ModalProvider from '@/provider'
import Box from "@mui/material/Box";
import Header from "@/components/header";
import Footer from '@/components/footer';
import Toolbar from "@mui/material/Toolbar";

export default function RootLayout(props: { children: React.ReactNode }) {
  const initialState = undefined;
  return (
    <html lang="en">
    <body>
    <AppRouterCacheProvider options={{ enableCssLayer: true }}>
      <ThemeProvider theme={theme}>
        {/* CssBaseline kickstart an elegant, consistent, and simple baseline to build upon. */}
        <CssBaseline />
        <Web3ModalProvider initialState={initialState}>
          <Box sx={{ display: 'flex' }}>
            <Box>
              <Header/>
            </Box>
            <Box component="main" sx={{ p: 3, flexGrow: 1 }}>
              <Toolbar/>
              <Box sx={{ flexGrow: 1 }}>
                {props.children}
              </Box>
            </Box>
            <Box>
              <Footer/>
            </Box>
          </Box>
        </Web3ModalProvider>
      </ThemeProvider>
    </AppRouterCacheProvider>
    </body>
    </html>
  );
}
