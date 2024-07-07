'use client';

import {config, projectId} from '@/wagmi'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {createWeb3Modal} from '@web3modal/wagmi/react'
import React, {ReactNode} from 'react'
import {State, WagmiProvider} from 'wagmi'
import { polygon, polygonAmoy } from 'wagmi/chains'

const queryClient = new QueryClient()

if (!projectId) throw new Error('Project ID is not defined')

createWeb3Modal({
  wagmiConfig: config,
  projectId: projectId,
  defaultChain: polygonAmoy,
})

function ContextProvider({
                           children,
                           initialState
                         }: {
  children: ReactNode
  initialState: State | undefined
}) {
  return (
    <WagmiProvider config={config} initialState={initialState}>
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    </WagmiProvider>
  )
}

export default ContextProvider
