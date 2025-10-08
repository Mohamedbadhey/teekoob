import React from 'react';
import {
  Drawer,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Divider,
  Box,
  Typography,
  Collapse,
  Tooltip
} from '@mui/material';
import {
  Dashboard as DashboardIcon,
  Book as BookIcon,
  Add as AddBookIcon,
  People as PeopleIcon,
  Category as CategoryIcon,
  Analytics as AnalyticsIcon,
  Settings as SettingsIcon,
  Shield as ShieldIcon,
  Payment as PaymentIcon,
  Storage as StorageIcon,
  Security as SecurityIcon,
  Notifications as NotificationsIcon,
  Backup as BackupIcon,
  ExpandLess,
  ExpandMore,
  TrendingUp as TrendingIcon,
  Assessment as AssessmentIcon,
  SystemUpdate as SystemIcon,
  AdminPanelSettings as AdminIcon,
  Radio as PodcastIcon,
  Headphones as HeadphonesIcon,
  Add as AddPodcastIcon
} from '@mui/icons-material';
import { useLocation, useNavigate } from 'react-router-dom';
import { useSelector, useDispatch } from 'react-redux';
import { RootState } from '../../store';
import { toggleSidebar } from '../../store/slices/uiSlice';

interface SidebarProps {
  open: boolean;
  onClose: () => void;
}

const Sidebar: React.FC<SidebarProps> = ({ open, onClose }) => {
  const location = useLocation();
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const sidebarOpen = useSelector((state: RootState) => state.ui.sidebarOpen);
  const [expandedSections, setExpandedSections] = React.useState<{
    [key: string]: boolean;
  }>({
    content: true,
    users: true,
    analytics: true,
    system: true,
  });

  const handleSectionToggle = (section: string) => {
    setExpandedSections(prev => ({
      ...prev,
      [section]: !prev[section]
    }));
  };

  const handleNavigation = (path: string) => {
    navigate(path);
    if (window.innerWidth < 768) {
      dispatch(toggleSidebar());
    }
  };

  const isActive = (path: string) => location.pathname === path;

  const menuItems = [
    {
      title: 'Dashboard',
      icon: <DashboardIcon />,
      path: '/admin',
      primary: true
    },
    {
      section: 'content',
      title: 'Content Management',
      icon: <BookIcon />,
      items: [
        { title: 'All Books', path: '/admin/books', icon: <BookIcon /> },
        { title: 'Add New Book', path: '/admin/books/new', icon: <AddBookIcon /> },
        { title: 'All Podcasts', path: '/admin/podcasts', icon: <PodcastIcon /> },
        { title: 'Add New Podcast', path: '/admin/podcasts/new', icon: <AddPodcastIcon /> },
        { title: 'Categories', path: '/admin/categories', icon: <CategoryIcon /> },
        { title: 'Content Moderation', path: '/admin/moderation', icon: <ShieldIcon /> }
      ]
    },
    {
      section: 'users',
      title: 'User Management',
      icon: <PeopleIcon />,
      items: [
        { title: 'All Users', path: '/admin/users', icon: <PeopleIcon /> },
        { title: 'User Analytics', path: '/admin/users/analytics', icon: <TrendingIcon /> },
        { title: 'User Reports', path: '/admin/users/reports', icon: <AssessmentIcon /> }
      ]
    },
    {
      section: 'analytics',
      title: 'Analytics & Insights',
      icon: <AnalyticsIcon />,
      items: [
        { title: 'Overview Dashboard', path: '/admin/analytics', icon: <DashboardIcon /> },
        { title: 'Advanced Analytics', path: '/admin/analytics/advanced', icon: <AnalyticsIcon /> },
        { title: 'Revenue Analytics', path: '/admin/analytics/revenue', icon: <TrendingIcon /> },
        { title: 'Content Performance', path: '/admin/analytics/content', icon: <AssessmentIcon /> }
      ]
    },
    {
      section: 'subscriptions',
      title: 'Subscriptions & Payments',
      icon: <PaymentIcon />,
      items: [
        { title: 'Subscription Plans', path: '/admin/subscriptions', icon: <PaymentIcon /> },
        { title: 'Payment History', path: '/admin/payments', icon: <AssessmentIcon /> },
        { title: 'Revenue Tracking', path: '/admin/revenue', icon: <TrendingIcon /> }
      ]
    },
    {
      section: 'system',
      title: 'System Administration',
      icon: <AdminIcon />,
      items: [
        { title: 'System Settings', path: '/admin/settings', icon: <SettingsIcon /> },
        { title: 'Security & Access', path: '/admin/security', icon: <SecurityIcon /> },
        { title: 'Backup & Restore', path: '/admin/backup', icon: <BackupIcon /> },
        { title: 'System Health', path: '/admin/health', icon: <SystemIcon /> },
        { title: 'Notifications', path: '/admin/notifications', icon: <NotificationsIcon /> },
        { title: 'Storage Management', path: '/admin/storage', icon: <StorageIcon /> }
      ]
    }
  ];

  const renderMenuItem = (item: any, index: number) => {
    if (item.primary) {
      return (
        <ListItem key={index} disablePadding>
          <ListItemButton
            onClick={() => handleNavigation(item.path)}
            selected={isActive(item.path)}
            sx={{
              '&.Mui-selected': {
                backgroundColor: 'primary.main',
                color: 'primary.contrastText',
                '&:hover': {
                  backgroundColor: 'primary.dark',
                },
              },
            }}
          >
            <ListItemIcon sx={{ color: 'inherit' }}>
              {item.icon}
            </ListItemIcon>
            <ListItemText primary={item.title} />
          </ListItemButton>
        </ListItem>
      );
    }

    if (item.section) {
      const isExpanded = expandedSections[item.section];
      
      return (
        <React.Fragment key={index}>
          <ListItem disablePadding>
            <ListItemButton onClick={() => handleSectionToggle(item.section)}>
              <ListItemIcon>{item.icon}</ListItemIcon>
              <ListItemText primary={item.title} />
              {isExpanded ? <ExpandLess /> : <ExpandMore />}
            </ListItemButton>
          </ListItem>
          
          <Collapse in={isExpanded} timeout="auto" unmountOnExit>
            <List component="div" disablePadding>
              {item.items.map((subItem: any, subIndex: number) => (
                <ListItem key={subIndex} disablePadding>
                  <ListItemButton
                    sx={{ pl: 4 }}
                    onClick={() => handleNavigation(subItem.path)}
                    selected={isActive(subItem.path)}
                  >
                    <ListItemIcon sx={{ minWidth: 36 }}>
                      {subItem.icon}
                    </ListItemIcon>
                    <ListItemText primary={subItem.title} />
                  </ListItemButton>
                </ListItem>
              ))}
            </List>
          </Collapse>
        </React.Fragment>
      );
    }

    return null;
  };

  return (
    <>
      {/* Desktop Sidebar - Permanent */}
      <Drawer
        variant="permanent"
        sx={{
          display: { xs: 'none', md: 'block' },
          '& .MuiDrawer-paper': {
            boxSizing: 'border-box',
            width: 280,
            backgroundColor: 'background.paper',
            borderRight: '1px solid',
            borderColor: 'divider',
            marginTop: '64px', // Header height
            height: 'calc(100% - 64px)',
          },
        }}
        open
      >
        <Box sx={{ p: 2, borderBottom: '1px solid', borderColor: 'divider' }}>
          <Typography variant="h6" color="primary" fontWeight="bold">
            Teekoob Admin
          </Typography>
          <Typography variant="caption" color="textSecondary">
            Complete Platform Control
          </Typography>
        </Box>
        
        <List sx={{ pt: 1 }}>
          {menuItems.map((item, index) => renderMenuItem(item, index))}
        </List>
        
        <Divider sx={{ mt: 'auto' }} />
        
        <Box sx={{ p: 2 }}>
          <Typography variant="caption" color="textSecondary" align="center" display="block">
            Admin Panel v1.0.0
          </Typography>
          <Typography variant="caption" color="textSecondary" align="center" display="block">
            © 2024 Teekoob
          </Typography>
        </Box>
      </Drawer>

      {/* Mobile Sidebar - Temporary */}
      <Drawer
        variant="temporary"
        open={open}
        onClose={onClose}
        ModalProps={{
          keepMounted: true, // Better open performance on mobile.
        }}
        sx={{
          display: { xs: 'block', md: 'none' },
          '& .MuiDrawer-paper': {
            boxSizing: 'border-box',
            width: 280,
            backgroundColor: 'background.paper',
            borderRight: '1px solid',
            borderColor: 'divider',
          },
        }}
      >
        <Box sx={{ p: 2, borderBottom: '1px solid', borderColor: 'divider' }}>
          <Typography variant="h6" color="primary" fontWeight="bold">
            Teekoob Admin
          </Typography>
          <Typography variant="caption" color="textSecondary">
            Complete Platform Control
          </Typography>
        </Box>
        
        <List sx={{ pt: 1 }}>
          {menuItems.map((item, index) => renderMenuItem(item, index))}
        </List>
        
        <Divider sx={{ mt: 'auto' }} />
        
        <Box sx={{ p: 2 }}>
          <Typography variant="caption" color="textSecondary" align="center" display="block">
            Admin Panel v1.0.0
          </Typography>
          <Typography variant="caption" color="textSecondary" align="center" display="block">
            © 2024 Teekoob
          </Typography>
        </Box>
      </Drawer>
    </>
  );
};

export default Sidebar;
