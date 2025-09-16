import React from 'react'
import { Outlet } from 'react-router-dom'
import { Box, CssBaseline } from '@mui/material'
import { useSelector, useDispatch } from 'react-redux'
import { RootState, AppDispatch } from '@/store'
import { toggleSidebar } from '@/store/slices/uiSlice'

import Sidebar from './Sidebar'
import Header from './Header'
import NotificationSystem from '../Common/NotificationSystem'

const Layout: React.FC = () => {
  const dispatch = useDispatch<AppDispatch>()
  const { sidebarOpen } = useSelector((state: RootState) => state.ui)

  const handleSidebarToggle = () => {
    dispatch(toggleSidebar())
  }

  return (
    <Box sx={{ display: 'flex' }}>
      <CssBaseline />
      
      {/* Header */}
      <Header onMenuClick={handleSidebarToggle} />
      
      {/* Sidebar */}
      <Sidebar open={sidebarOpen} onClose={() => dispatch(toggleSidebar())} />
      
      {/* Main Content */}
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          p: 3,
          width: { sm: `calc(100% - ${280}px)` },
          marginTop: '64px', // Header height
          marginLeft: { xs: 0, sm: '280px' },
          transition: 'margin-left 0.3s ease',
        }}
      >
        <Outlet />
      </Box>
      
      {/* Notification System */}
      <NotificationSystem />
    </Box>
  )
}

export default Layout
