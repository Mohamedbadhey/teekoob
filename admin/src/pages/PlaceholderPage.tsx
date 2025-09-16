import React from 'react';
import { Box, Typography, Paper, Container } from '@mui/material';
import { useLocation } from 'react-router-dom';

const PlaceholderPage: React.FC = () => {
  const location = useLocation();
  const path = location.pathname.split('/').pop() || 'Page';
  const title = path.charAt(0).toUpperCase() + path.slice(1).replace(/-/g, ' ');

  return (
    <Container maxWidth="lg">
      <Box sx={{ mt: 4, mb: 4 }}>
        <Paper sx={{ p: 4, textAlign: 'center' }}>
          <Typography variant="h4" component="h1" gutterBottom>
            {title}
          </Typography>
          <Typography variant="body1" color="text.secondary">
            This page is under development. The {title.toLowerCase()} functionality will be implemented soon.
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
            Current path: {location.pathname}
          </Typography>
        </Paper>
      </Box>
    </Container>
  );
};

export default PlaceholderPage;
