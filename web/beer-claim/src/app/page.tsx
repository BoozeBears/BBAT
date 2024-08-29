"use client";

//export const runtime = 'edge';

import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';

export default function Home() {
  return (<Box>
      <Box>
        <Typography variant="h3">Disclaimer</Typography>
        <Typography variant="body1">
          - No support from MBS when burn/claim beer failed
        </Typography>
        <Typography variant="body1">
          - Wrongly burned tokens can not be restored
        </Typography>
      </Box>
    </Box>);
}
