import React from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Box,
  Typography,
  Button,
  Container,
  Paper,
} from '@mui/material'
import {
  Home as HomeIcon,
  ArrowBack as ArrowBackIcon,
} from '@mui/icons-material'

const NotFoundPage: React.FC = () => {
  const navigate = useNavigate()

  return (
    <Container maxWidth="md">
      <Box
        display="flex"
        flexDirection="column"
        alignItems="center"
        justifyContent="center"
        minHeight="80vh"
        textAlign="center"
      >
        <Paper
          elevation={3}
          sx={{
            p: 6,
            borderRadius: 3,
            backgroundColor: 'background.paper',
          }}
        >
          {/* 404 Icon */}
          <Typography
            variant="h1"
            component="div"
            sx={{
              fontSize: '8rem',
              fontWeight: 'bold',
              color: 'primary.main',
              mb: 2,
              lineHeight: 1,
            }}
          >
            404
          </Typography>

          {/* Error Message */}
          <Typography variant="h4" component="h1" gutterBottom>
            Page Not Found
          </Typography>

          <Typography variant="body1" color="textSecondary" sx={{ mb: 4 }}>
            The page you are looking for doesn't exist or has been moved.
          </Typography>

          {/* Action Buttons */}
          <Box display="flex" gap={2} justifyContent="center" flexWrap="wrap">
            <Button
              variant="outlined"
              startIcon={<ArrowBackIcon />}
              onClick={() => navigate(-1)}
              size="large"
            >
              Go Back
            </Button>
            <Button
              variant="contained"
              startIcon={<HomeIcon />}
              onClick={() => navigate('/dashboard')}
              size="large"
            >
              Go to Dashboard
            </Button>
          </Box>

          {/* Help Text */}
          <Typography variant="body2" color="textSecondary" sx={{ mt: 4 }}>
            If you believe this is an error, please contact the administrator.
          </Typography>
        </Paper>
      </Box>
    </Container>
  )
}

export default NotFoundPage
