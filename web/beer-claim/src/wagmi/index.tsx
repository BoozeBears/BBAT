'use client';

import { defaultWagmiConfig } from '@web3modal/wagmi/react/config'

import { http, createStorage } from 'wagmi'
import { polygonAmoy } from 'wagmi/chains'

// Get projectId from https://cloud.walletconnect.com
export const projectId = process.env.NEXT_PUBLIC_PROJECT_ID

if (!projectId) throw new Error('Project ID is not defined')

const metadata = {
  name: 'Beer Claim',
  description: 'Claim your MBS beer',
  url: 'https://mbs.boozebears.com', // origin must match your domain & subdomain
  icons: ['https://avatars.githubusercontent.com/u/37784886']
}

// Create wagmiConfig
const chains = [polygonAmoy] as const
export const config = defaultWagmiConfig({
  chains,
  projectId,
  metadata,
  transports: {
    [polygonAmoy.id]: http(),
  },
})
