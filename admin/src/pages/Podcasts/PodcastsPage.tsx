import React, { useState, useMemo, useEffect } from 'react';
import {
  Box,
  Typography,
  Button,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
  IconButton,
  Tooltip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Alert,
  Snackbar,
  Card,
  CardContent,
  Grid,
  Avatar,
  Switch,
  FormControlLabel,
  Divider,
  Badge,
  Tabs,
  Tab,
  Rating,
  LinearProgress,
  useTheme,
  useMediaQuery,
  Stepper,
  Step,
  StepLabel,
  StepContent,
  FormHelperText,
  InputAdornment,
  Collapse
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Visibility as ViewIcon,
  Block as BlockIcon,
  CheckCircle as CheckIcon,
  Warning as WarningIcon,
  Download as DownloadIcon,
  FilterList as FilterIcon,
  Refresh as RefreshIcon,
  Search as SearchIcon,
  Radio as PodcastIcon,
  AudioFile as AudioIcon,
  Language as LanguageIcon,
  Category as CategoryIcon,
  CloudUpload as UploadIcon,
  Close as CloseIcon,
  ExpandMore as ExpandMoreIcon,
  ExpandLess as ExpandLessIcon,
  PlayArrow as PlayIcon,
  Headphones as HeadphonesIcon
} from '@mui/icons-material';
import { DataGrid, GridColDef, GridActionsCellItem, GridToolbar } from '@mui/x-data-grid';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { 
  getPodcasts, 
  getPodcastStats, 
  updatePodcastStatus, 
  bulkUpdatePodcasts,
  deletePodcast,
  createPodcast,
  updatePodcast,
  getCategories,
  getPodcast
} from '../../services/adminAPI';
import { useNavigate } from 'react-router-dom';
import { format } from 'date-fns';
import { useDropzone } from 'react-dropzone';

interface Podcast {
  id: string;
  title: string;
  title_somali: string;
  description: string;
  description_somali: string;
  host: string;
  host_somali: string;
  language: 'en' | 'so' | 'ar';
  cover_image_url?: string;
  rss_feed_url?: string;
  website_url?: string;
  total_episodes?: number;
  rating?: number;
  review_count?: number;
  is_featured: boolean;
  is_new_release: boolean;
  is_premium: boolean;
  is_free: boolean;
  metadata?: any;
  created_at: string;
  updated_at: string;
  categories?: string[];
  categoryNames?: string[];
  categoryNamesSomali?: string[];
}

interface PodcastStats {
  totalPodcasts: number;
  featuredPodcasts: number;
  newReleases: number;
  premiumPodcasts: number;
  totalEpisodes: number;
  averageRating: number;
  podcastsByLanguage: Record<string, number>;
}

interface PodcastFormData {
  title: string;
  title_somali: string;
  description: string;
  description_somali: string;
  host: string;
  host_somali: string;
  selectedCategories: string[];
  language: 'en' | 'so' | 'ar';
  rss_feed_url: string;
  website_url: string;
  is_featured: boolean;
  is_new_release: boolean;
  is_premium: boolean;
  is_free: boolean;
}

const PodcastsPage: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  
  // State
  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');
  const [languageFilter, setLanguageFilter] = useState<string>('all');
  const [featuredFilter, setFeaturedFilter] = useState<string>('all');
  const [selectedPodcasts, setSelectedPodcasts] = useState<string[]>([]);
  const [bulkAction, setBulkAction] = useState<string>('');
  const [showBulkDialog, setShowBulkDialog] = useState(false);
  const [showPodcastDialog, setShowPodcastDialog] = useState(false);
  const [selectedPodcast, setSelectedPodcast] = useState<Podcast | null>(null);
  const [activeTab, setActiveTab] = useState(0);
  const [activeStep, setActiveStep] = useState(0);
  const [expandedFilters, setExpandedFilters] = useState(false);
  const [dataGridKey, setDataGridKey] = useState(0);

  // Force DataGrid to re-render when screen size changes
  useEffect(() => {
    const handleResize = () => {
      setDataGridKey(prev => prev + 1);
    };

    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  // Form state
  const [formData, setFormData] = useState<PodcastFormData>({
    title: '',
    title_somali: '',
    description: '',
    description_somali: '',
    host: '',
    host_somali: '',
    selectedCategories: [],
    language: 'en',
    rss_feed_url: '',
    website_url: '',
    is_featured: false,
    is_new_release: false,
    is_premium: false,
    is_free: true
  });

  // File upload state
  const [uploadedFiles, setUploadedFiles] = useState<{
    cover?: File;
  }>({});

  // Fetch podcasts with enhanced query
  const { data: podcastsData, isLoading, error } = useQuery({
    queryKey: ['podcasts', { search: searchTerm, category: categoryFilter, language: languageFilter, featured: featuredFilter }],
    queryFn: () => getPodcasts({ 
      search: searchTerm, 
      category: categoryFilter === 'all' ? undefined : categoryFilter,
      language: languageFilter === 'all' ? undefined : languageFilter,
      featured: featuredFilter === 'all' ? undefined : featuredFilter === 'true'
    }),
    staleTime: 30000,
  });

  // Fetch podcast statistics
  const { data: podcastStats } = useQuery({
    queryKey: ['podcastStats'],
    queryFn: () => getPodcastStats(),
    staleTime: 60000,
  });

  // Fetch categories for category filter
  const { data: categories } = useQuery({
    queryKey: ['podcastCategories'],
    queryFn: () => getCategories(),
    staleTime: 300000, // 5 minutes
  });

  // Force DataGrid to re-render after initial load to fix scroll issues
  useEffect(() => {
    const timer = setTimeout(() => {
      setDataGridKey(prev => prev + 1);
    }, 100);

    return () => clearTimeout(timer);
  }, [podcastsData]);

  // Mutations
  const updatePodcastStatusMutation = useMutation({
    mutationFn: ({ id, statusData }: { id: string; statusData: any }) => updatePodcastStatus(id, statusData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['podcasts'] });
      queryClient.invalidateQueries({ queryKey: ['podcastStats'] });
    },
  });

  const bulkUpdatePodcastsMutation = useMutation({
    mutationFn: bulkUpdatePodcasts,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['podcasts'] });
      queryClient.invalidateQueries({ queryKey: ['podcastStats'] });
      setSelectedPodcasts([]);
      setShowBulkDialog(false);
    },
  });

  const deletePodcastMutation = useMutation({
    mutationFn: deletePodcast,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['podcasts'] });
      queryClient.invalidateQueries({ queryKey: ['podcastStats'] });
    },
  });

  const createPodcastMutation = useMutation({
    mutationFn: createPodcast,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['podcasts'] });
      queryClient.invalidateQueries({ queryKey: ['podcastStats'] });
      setShowPodcastDialog(false);
      resetForm();
    },
  });

  const updatePodcastMutation = useMutation({
    mutationFn: (data: { id: string; podcastData: FormData }) => updatePodcast(data.id, data.podcastData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['podcasts'] });
      queryClient.invalidateQueries({ queryKey: ['podcastStats'] });
      setShowPodcastDialog(false);
      resetForm();
    },
  });

  // File dropzone
  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop: (acceptedFiles) => {
      // Handle file uploads
      acceptedFiles.forEach(file => {
        if (file.type.startsWith('image/')) {
          setUploadedFiles(prev => ({ ...prev, cover: file }));
        }
      });
    },
    accept: {
      'image/*': ['.jpeg', '.jpg', '.png', '.webp', '.gif']
    }
  });

  // Enhanced columns with responsive design
  const columns: GridColDef[] = useMemo(() => [
    {
      field: 'cover',
      headerName: 'Cover',
      width: isMobile ? 80 : 120,
      renderCell: (params) => (
        <Avatar
          variant="rounded"
          src={params.row.cover_image_url}
          alt={params.row.title}
          sx={{ width: isMobile ? 50 : 70, height: isMobile ? 65 : 90 }}
        >
          <PodcastIcon />
        </Avatar>
      ),
    },
    {
      field: 'title',
      headerName: 'Title',
      width: isMobile ? 200 : 300,
      flex: isMobile ? 0 : 1,
      renderCell: (params) => (
        <Box>
          <Typography variant="body2" fontWeight="medium" noWrap>
            {params.row.title}
          </Typography>
          {params.row.title_somali && (
            <Typography variant="caption" color="textSecondary" noWrap>
              {params.row.title_somali}
            </Typography>
          )}
        </Box>
      ),
    },
    {
      field: 'host',
      headerName: 'Host',
      width: isMobile ? 120 : 180,
      renderCell: (params) => (
        <Typography variant="body2" noWrap>
          {params.row.host}
        </Typography>
      ),
    },
    {
      field: 'categories',
      headerName: 'Categories',
      width: isMobile ? 120 : 180,
      renderCell: (params) => (
        <Box display="flex" flexWrap="wrap" gap={0.5}>
          {params.row.categoryNames && params.row.categoryNames.length > 0 ? (
            params.row.categoryNames.map((category: string, index: number) => (
              <Chip 
                key={index}
                label={category} 
                size="small"
                color="primary"
                variant="filled"
                sx={{ fontSize: '0.7rem', height: 20 }}
              />
            ))
          ) : (
            <Chip 
              label="No categories" 
              size="small"
              color="default"
              variant="outlined"
              sx={{ fontSize: '0.7rem', height: 20 }}
            />
          )}
        </Box>
      ),
    },
    {
      field: 'language',
      headerName: 'Language',
      width: isMobile ? 80 : 100,
      renderCell: (params) => (
        <Box display="flex" alignItems="center">
          <LanguageIcon sx={{ mr: 0.5, fontSize: 16 }} />
          <Typography variant="body2" noWrap>
            {params.row.language.toUpperCase()}
          </Typography>
        </Box>
      ),
    },
    {
      field: 'episodes',
      headerName: 'Episodes',
      width: isMobile ? 80 : 120,
      renderCell: (params) => (
        <Box display="flex" alignItems="center">
          <HeadphonesIcon sx={{ mr: 0.5, fontSize: 16 }} />
          <Typography variant="body2" noWrap>
            {params.row.total_episodes || 0}
          </Typography>
        </Box>
      ),
    },
    {
      field: 'rating',
      headerName: 'Rating',
      width: isMobile ? 120 : 160,
      renderCell: (params) => (
        <Box>
          <Rating value={parseFloat(params.row.rating) || 0} readOnly size="small" />
          <Typography variant="caption" display="block">
            {params.row.review_count || 0} reviews
          </Typography>
        </Box>
      ),
    },
    {
      field: 'features',
      headerName: 'Features',
      width: isMobile ? 120 : 180,
      renderCell: (params) => (
        <Box>
          {params.row.is_featured && (
            <Chip label="Featured" color="success" size="small" sx={{ mb: 0.5 }} />
          )}
          {params.row.is_new_release && (
            <Chip label="New" color="warning" size="small" sx={{ mb: 0.5 }} />
          )}
          {params.row.is_premium && (
            <Chip label="Premium" color="info" size="small" sx={{ mb: 0.5 }} />
          )}
          {params.row.is_free && (
            <Chip label="Free" color="secondary" size="small" />
          )}
        </Box>
      ),
    },
    {
      field: 'createdAt',
      headerName: 'Added',
      width: isMobile ? 100 : 130,
      valueGetter: (params) => format(new Date(params.row.created_at), 'MMM dd, yyyy'),
    },
    {
      field: 'actions',
      headerName: 'Actions',
      width: isMobile ? 150 : 220,
      type: 'actions',
      getActions: (params) => [
        <GridActionsCellItem
          icon={<ViewIcon />}
          label="View Podcast"
          onClick={() => handleViewPodcast(params.row)}
        />,
        <GridActionsCellItem
          icon={<HeadphonesIcon />}
          label="Manage Episodes"
          onClick={() => handleManageEpisodes(params.row)}
        />,
        <GridActionsCellItem
          icon={<EditIcon />}
          label="Edit Podcast"
          onClick={() => handleEditPodcast(params.row)}
        />,
        <GridActionsCellItem
          icon={params.row.is_featured ? <BlockIcon /> : <CheckIcon />}
          label={params.row.is_featured ? 'Unfeature' : 'Feature'}
          onClick={() => handleToggleFeatured(params.row.id, !params.row.is_featured)}
        />,
        <GridActionsCellItem
          icon={<DeleteIcon />}
          label="Delete Podcast"
          onClick={() => handleDeletePodcast(params.row.id)}
        />,
      ],
    },
  ], [isMobile]);

  // Enhanced podcast statistics cards with responsive design
  const renderPodcastStats = () => (
    <Grid container spacing={isMobile ? 2 : 3} sx={{ mb: 3 }}>
      <Grid item xs={6} sm={6} md={3}>
        <Card>
          <CardContent sx={{ p: isMobile ? 1.5 : 2 }}>
            <Box display="flex" alignItems="center">
              <PodcastIcon color="primary" sx={{ mr: 1, fontSize: isMobile ? 30 : 40 }} />
              <Box>
                <Typography variant={isMobile ? "h5" : "h4"}>{podcastStats?.totalPodcasts || 0}</Typography>
                <Typography variant="body2" color="textSecondary" noWrap>Total Podcasts</Typography>
              </Box>
            </Box>
          </CardContent>
        </Card>
      </Grid>
      <Grid item xs={6} sm={6} md={3}>
        <Card>
          <CardContent sx={{ p: isMobile ? 1.5 : 2 }}>
            <Box display="flex" alignItems="center">
              <CheckIcon color="success" sx={{ mr: 1, fontSize: isMobile ? 30 : 40 }} />
              <Box>
                <Typography variant={isMobile ? "h5" : "h4"}>{podcastStats?.featuredPodcasts || 0}</Typography>
                <Typography variant="body2" color="textSecondary" noWrap>Featured</Typography>
              </Box>
            </Box>
          </CardContent>
        </Card>
      </Grid>
      <Grid item xs={6} sm={6} md={3}>
        <Card>
          <CardContent sx={{ p: isMobile ? 1.5 : 2 }}>
            <Box display="flex" alignItems="center">
              <WarningIcon color="warning" sx={{ mr: 1, fontSize: isMobile ? 30 : 40 }} />
              <Box>
                <Typography variant={isMobile ? "h5" : "h4"}>{podcastStats?.newReleases || 0}</Typography>
                <Typography variant="body2" color="textSecondary" noWrap>New Releases</Typography>
              </Box>
            </Box>
          </CardContent>
        </Card>
      </Grid>
      <Grid item xs={6} sm={6} md={3}>
        <Card>
          <CardContent sx={{ p: isMobile ? 1.5 : 2 }}>
            <Box display="flex" alignItems="center">
              <HeadphonesIcon color="info" sx={{ mr: 1, fontSize: isMobile ? 30 : 40 }} />
              <Box>
                <Typography variant={isMobile ? "h5" : "h4"}>{podcastStats?.totalEpisodes || 0}</Typography>
                <Typography variant="body2" color="textSecondary" noWrap>Total Episodes</Typography>
              </Box>
            </Box>
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  );

  // Enhanced filters with responsive design and collapsible on mobile
  const renderFilters = () => (
    <Card sx={{ mb: 3 }}>
      <CardContent>
        <Box display="flex" justifyContent="space-between" alignItems="center" sx={{ mb: 2 }}>
          <Typography variant="h6">Filters & Actions</Typography>
          {isMobile && (
            <IconButton onClick={() => setExpandedFilters(!expandedFilters)}>
              {expandedFilters ? <ExpandLessIcon /> : <ExpandMoreIcon />}
            </IconButton>
          )}
        </Box>
        
        <Collapse in={!isMobile || expandedFilters}>
          <Grid container spacing={2} alignItems="center">
            <Grid item xs={12} md={3}>
              <TextField
                fullWidth
                size="small"
                placeholder="Search podcasts..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                InputProps={{
                  startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />,
                }}
              />
            </Grid>
            <Grid item xs={6} md={2}>
              <FormControl fullWidth size="small">
                <InputLabel>Category</InputLabel>
                <Select
                  value={categoryFilter}
                  onChange={(e) => setCategoryFilter(e.target.value)}
                  label="Category"
                >
                  <MenuItem value="all">All Categories</MenuItem>
                  {categories?.map((category: any) => (
                    <MenuItem key={category.id} value={category.id}>
                      {category.name}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={6} md={2}>
              <FormControl fullWidth size="small">
                <InputLabel>Language</InputLabel>
                <Select
                  value={languageFilter}
                  onChange={(e) => setLanguageFilter(e.target.value)}
                  label="Language"
                >
                  <MenuItem value="all">All Languages</MenuItem>
                  <MenuItem value="en">English</MenuItem>
                  <MenuItem value="so">Somali</MenuItem>
                  <MenuItem value="ar">Arabic</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={6} md={2}>
              <FormControl fullWidth size="small">
                <InputLabel>Featured</InputLabel>
                <Select
                  value={featuredFilter}
                  onChange={(e) => setFeaturedFilter(e.target.value)}
                  label="Featured"
                >
                  <MenuItem value="all">All</MenuItem>
                  <MenuItem value="true">Featured</MenuItem>
                  <MenuItem value="false">Not Featured</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={6} md={3}>
              <Box display="flex" gap={1} flexDirection={isMobile ? 'column' : 'row'}>
                <Button
                  variant="outlined"
                  size="small"
                  startIcon={<FilterIcon />}
                  onClick={() => setShowBulkDialog(true)}
                  disabled={selectedPodcasts.length === 0}
                  fullWidth={isMobile}
                >
                  Bulk Actions ({selectedPodcasts.length})
                </Button>
                <Button
                  variant="outlined"
                  size="small"
                  startIcon={<DownloadIcon />}
                  onClick={() => handleExportPodcasts()}
                  fullWidth={isMobile}
                >
                  Export
                </Button>
                <Button
                  variant="outlined"
                  size="small"
                  startIcon={<RefreshIcon />}
                  onClick={() => queryClient.invalidateQueries({ queryKey: ['podcasts'] })}
                  fullWidth={isMobile}
                >
                  Refresh
                </Button>
              </Box>
            </Grid>
          </Grid>
        </Collapse>
      </CardContent>
    </Card>
  );

  // Enhanced podcast form dialog with stepper
  const renderPodcastDialog = () => (
    <Dialog 
      open={showPodcastDialog} 
      onClose={() => setShowPodcastDialog(false)} 
      maxWidth="lg" 
      fullWidth
      fullScreen={isMobile}
    >
      <DialogTitle>
        {selectedPodcast ? `Edit Podcast: ${selectedPodcast.title}` : 'Add New Podcast'}
        {isMobile && (
          <IconButton
            aria-label="close"
            onClick={() => setShowPodcastDialog(false)}
            sx={{ position: 'absolute', right: 8, top: 8 }}
          >
            <CloseIcon />
          </IconButton>
        )}
      </DialogTitle>
      <DialogContent>
        <Stepper activeStep={activeStep} orientation={isMobile ? 'vertical' : 'horizontal'} sx={{ mb: 3 }}>
          <Step>
            <StepLabel>Basic Information</StepLabel>
          </Step>
          <Step>
            <StepLabel>Details & Links</StepLabel>
          </Step>
          <Step>
            <StepLabel>Files & Media</StepLabel>
          </Step>
          <Step>
            <StepLabel>Settings & Features</StepLabel>
          </Step>
        </Stepper>

        {/* Step 1: Basic Information */}
        {activeStep === 0 && (
          <Grid container spacing={2}>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Title (English) *"
                value={formData.title}
                onChange={(e) => setFormData(prev => ({ ...prev, title: e.target.value }))}
                required
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Title (Somali) *"
                value={formData.title_somali}
                onChange={(e) => setFormData(prev => ({ ...prev, title_somali: e.target.value }))}
                required
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                multiline
                rows={3}
                label="Description (English) *"
                value={formData.description}
                onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
                required
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                multiline
                rows={3}
                label="Description (Somali) *"
                value={formData.description_somali}
                onChange={(e) => setFormData(prev => ({ ...prev, description_somali: e.target.value }))}
                required
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Host (English) *"
                value={formData.host}
                onChange={(e) => setFormData(prev => ({ ...prev, host: e.target.value }))}
                placeholder="Enter host name"
                required
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Host (Somali) *"
                value={formData.host_somali}
                onChange={(e) => setFormData(prev => ({ ...prev, host_somali: e.target.value }))}
                placeholder="Enter host name"
                required
              />
            </Grid>
            <Grid item xs={12}>
              <FormControl fullWidth required>
                <InputLabel>Categories *</InputLabel>
                <Select
                  multiple
                  value={formData.selectedCategories}
                  onChange={(e) => setFormData(prev => ({ ...prev, selectedCategories: e.target.value as string[] }))}
                  label="Categories *"
                  renderValue={(selected) => (
                    <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                      {selected.map((value) => {
                        const category = categories?.find(cat => cat.id === value);
                        return (
                          <Chip 
                            key={value} 
                            label={category?.name || value} 
                            size="small"
                            color="primary"
                            variant="outlined"
                          />
                        );
                      })}
                    </Box>
                  )}
                >
                  {categories?.map((category: any) => (
                    <MenuItem key={category.id} value={category.id}>
                      <Box>
                        <Typography variant="body2" fontWeight="medium">
                          {category.name}
                        </Typography>
                        {category.name_somali && (
                          <Typography variant="caption" color="text.secondary">
                            {category.name_somali}
                          </Typography>
                        )}
                      </Box>
                    </MenuItem>
                  ))}
                </Select>
                <FormHelperText>
                  Select one or more categories for this podcast
                </FormHelperText>
              </FormControl>
            </Grid>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth required>
                <InputLabel>Language</InputLabel>
                <Select
                  value={formData.language}
                  onChange={(e) => setFormData(prev => ({ ...prev, language: e.target.value as 'en' | 'so' | 'ar' }))}
                  label="Language"
                >
                  <MenuItem value="en">English</MenuItem>
                  <MenuItem value="so">Somali</MenuItem>
                  <MenuItem value="ar">Arabic</MenuItem>
                </Select>
              </FormControl>
            </Grid>
          </Grid>
        )}

        {/* Step 2: Details & Links */}
        {activeStep === 1 && (
          <Grid container spacing={2}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="RSS Feed URL"
                value={formData.rss_feed_url}
                onChange={(e) => setFormData(prev => ({ ...prev, rss_feed_url: e.target.value }))}
                placeholder="https://example.com/podcast.rss"
                helperText="Optional: RSS feed URL for podcast distribution"
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Website URL"
                value={formData.website_url}
                onChange={(e) => setFormData(prev => ({ ...prev, website_url: e.target.value }))}
                placeholder="https://example.com/podcast"
                helperText="Optional: Official website URL for the podcast"
              />
            </Grid>
          </Grid>
        )}

        {/* Step 3: Files & Media */}
        {activeStep === 2 && (
          <Grid container spacing={2}>
            <Grid item xs={12}>
              <Typography variant="h6" gutterBottom>Cover Image Upload</Typography>
              <Typography variant="body2" color="textSecondary" sx={{ mb: 2 }}>
                Drag and drop cover image here or click to select
              </Typography>
              
              <Box
                {...getRootProps()}
                sx={{
                  border: '2px dashed',
                  borderColor: isDragActive ? 'primary.main' : 'grey.300',
                  borderRadius: 1,
                  p: 3,
                  textAlign: 'center',
                  cursor: 'pointer',
                  bgcolor: isDragActive ? 'action.hover' : 'background.paper',
                  '&:hover': {
                    bgcolor: 'action.hover',
                  }
                }}
              >
                <input {...getInputProps()} />
                <UploadIcon sx={{ fontSize: 48, color: 'primary.main', mb: 1 }} />
                <Typography variant="h6" gutterBottom>
                  {isDragActive ? 'Drop image here' : 'Upload Cover Image'}
                </Typography>
                <Typography variant="body2" color="textSecondary">
                  Supported: Images (JPG, PNG, WebP, GIF)
                </Typography>
              </Box>

              {/* File previews */}
              {Object.entries(uploadedFiles).map(([key, file]) => (
                <Box key={key} sx={{ mt: 2, p: 2, border: '1px solid', borderColor: 'divider', borderRadius: 1 }}>
                  <Box display="flex" justifyContent="space-between" alignItems="center">
                    <Typography variant="body2">
                      {key}: {file.name}
                    </Typography>
                    <IconButton size="small" onClick={() => {
                      setUploadedFiles(prev => {
                        const newFiles = { ...prev };
                        delete newFiles[key as keyof typeof uploadedFiles];
                        return newFiles;
                      });
                    }}>
                      <CloseIcon />
                    </IconButton>
                  </Box>
                </Box>
              ))}

              {/* Existing file URLs */}
              {selectedPodcast && (
                <Grid container spacing={2} sx={{ mt: 2 }}>
                  <Grid item xs={12}>
                    <TextField
                      fullWidth
                      label="Cover Image URL"
                      defaultValue={selectedPodcast.cover_image_url}
                      helperText="Current cover image URL"
                    />
                  </Grid>
                </Grid>
              )}
            </Grid>
          </Grid>
        )}

        {/* Step 4: Settings & Features */}
        {activeStep === 3 && (
          <Grid container spacing={2}>
            <Grid item xs={12}>
              <Typography variant="h6" gutterBottom>Podcast Features & Settings</Typography>
            </Grid>
            <Grid item xs={12} sm={4}>
              <FormControlLabel
                control={
                  <Switch 
                    checked={formData.is_featured}
                    onChange={(e) => setFormData(prev => ({ ...prev, is_featured: e.target.checked }))}
                  />
                }
                label="Featured Podcast"
              />
            </Grid>
            <Grid item xs={12} sm={4}>
              <FormControlLabel
                control={
                  <Switch 
                    checked={formData.is_new_release}
                    onChange={(e) => setFormData(prev => ({ ...prev, is_new_release: e.target.checked }))}
                  />
                }
                label="New Release"
              />
            </Grid>
            <Grid item xs={12} sm={4}>
              <FormControlLabel
                control={
                  <Switch 
                    checked={formData.is_premium}
                    onChange={(e) => setFormData(prev => ({ ...prev, is_premium: e.target.checked }))}
                  />
                }
                label="Premium Content"
              />
            </Grid>
            <Grid item xs={12} sm={4}>
              <FormControlLabel
                control={
                  <Switch 
                    checked={formData.is_free}
                    onChange={(e) => setFormData(prev => ({ ...prev, is_free: e.target.checked }))}
                  />
                }
                label="Free Podcast"
              />
            </Grid>
          </Grid>
        )}

        {/* Navigation buttons */}
        <Box sx={{ display: 'flex', justifyContent: 'space-between', mt: 3 }}>
          <Button
            disabled={activeStep === 0}
            onClick={() => setActiveStep((prevActiveStep) => prevActiveStep - 1)}
          >
            Back
          </Button>
          <Box>
            {activeStep === 3 ? (
              <Button
                variant="contained"
                onClick={handleSavePodcast}
                disabled={!isFormValid()}
              >
                {selectedPodcast ? 'Update Podcast' : 'Create Podcast'}
              </Button>
            ) : (
              <Button
                variant="contained"
                onClick={() => setActiveStep((prevActiveStep) => prevActiveStep + 1)}
                disabled={!isStepValid(activeStep)}
              >
                Next
              </Button>
            )}
          </Box>
        </Box>
      </DialogContent>
    </Dialog>
  );

  // Enhanced bulk actions dialog
  const renderBulkActionsDialog = () => (
    <Dialog open={showBulkDialog} onClose={() => setShowBulkDialog(false)} maxWidth="sm" fullWidth>
      <DialogTitle>Bulk Actions</DialogTitle>
      <DialogContent>
        <Typography variant="body2" sx={{ mb: 2 }}>
          Apply actions to {selectedPodcasts.length} selected podcasts
        </Typography>
        <FormControl fullWidth sx={{ mb: 2 }}>
          <InputLabel>Action</InputLabel>
          <Select
            value={bulkAction}
            onChange={(e) => setBulkAction(e.target.value)}
            label="Action"
          >
            <MenuItem value="feature">Feature Podcasts</MenuItem>
            <MenuItem value="unfeature">Unfeature Podcasts</MenuItem>
            <MenuItem value="markNew">Mark as New Release</MenuItem>
            <MenuItem value="markPremium">Mark as Premium</MenuItem>
            <MenuItem value="delete">Delete Podcasts</MenuItem>
          </Select>
        </FormControl>
        {bulkAction === 'delete' && (
          <Alert severity="warning">
            This action cannot be undone. All selected podcasts will be permanently deleted.
          </Alert>
        )}
      </DialogContent>
      <DialogActions>
        <Button onClick={() => setShowBulkDialog(false)}>Cancel</Button>
        <Button 
          variant="contained" 
          color={bulkAction === 'delete' ? 'error' : 'primary'}
          onClick={handleBulkAction}
          disabled={!bulkAction}
        >
          Apply Action
        </Button>
      </DialogActions>
    </Dialog>
  );

  // Form validation
  const isStepValid = (step: number) => {
    switch (step) {
      case 0:
        return formData.title && formData.title_somali && formData.description && 
               formData.description_somali && formData.host && formData.host_somali && 
               formData.selectedCategories.length > 0;
      case 1:
        return true; // Optional fields
      case 2:
        return true; // Optional files
      case 3:
        return true; // Optional settings
      default:
        return false;
    }
  };

  const isFormValid = () => {
    return isStepValid(0); // At least basic info is required
  };

  // Reset form
  const resetForm = () => {
    setFormData({
      title: '',
      title_somali: '',
      description: '',
      description_somali: '',
      host: '',
      host_somali: '',
      selectedCategories: [],
      language: 'en',
      rss_feed_url: '',
      website_url: '',
      is_featured: false,
      is_new_release: false,
      is_premium: false,
      is_free: true
    });
    setUploadedFiles({});
    setActiveStep(0);
  };

  // Event handlers
  const handleViewPodcast = (podcast: Podcast) => {
    setSelectedPodcast(podcast);
    setShowPodcastDialog(true);
    setActiveStep(0);
  };

  const handleManageEpisodes = (podcast: Podcast) => {
    navigate(`/admin/podcasts/${podcast.id}/episodes`);
  };

  const handleEditPodcast = async (podcast: Podcast) => {
    try {
      const completePodcastData = await getPodcast(podcast.id);
      
      setSelectedPodcast(completePodcastData || podcast);
      setFormData({
        title: completePodcastData?.title || podcast.title,
        title_somali: completePodcastData?.title_somali || podcast.title_somali,
        description: completePodcastData?.description || podcast.description,
        description_somali: completePodcastData?.description_somali || podcast.description_somali,
        host: completePodcastData?.host || podcast.host,
        host_somali: completePodcastData?.host_somali || podcast.host_somali,
        selectedCategories: completePodcastData?.categories || podcast.categories || [],
        language: completePodcastData?.language || podcast.language,
        rss_feed_url: completePodcastData?.rss_feed_url || '',
        website_url: completePodcastData?.website_url || '',
        is_featured: Boolean(completePodcastData?.is_featured ?? podcast.is_featured),
        is_new_release: Boolean(completePodcastData?.is_new_release ?? podcast.is_new_release),
        is_premium: Boolean(completePodcastData?.is_premium ?? podcast.is_premium),
        is_free: Boolean(completePodcastData?.is_free ?? podcast.is_free)
      });
      
    } catch (error) {
      console.error('Error fetching complete podcast data:', error);
      setSelectedPodcast(podcast);
      setFormData({
        title: podcast.title,
        title_somali: podcast.title_somali,
        description: podcast.description,
        description_somali: podcast.description_somali,
        host: podcast.host,
        host_somali: podcast.host_somali,
        selectedCategories: podcast.categories || [],
        language: podcast.language,
        rss_feed_url: '',
        website_url: '',
        is_featured: Boolean(podcast.is_featured),
        is_new_release: Boolean(podcast.is_new_release),
        is_premium: Boolean(podcast.is_premium),
        is_free: Boolean(podcast.is_free)
      });
    }
    
    setShowPodcastDialog(true);
    setActiveStep(0);
  };

  const handleToggleFeatured = (podcastId: string, isFeatured: boolean) => {
    updatePodcastStatusMutation.mutate({ id: podcastId, statusData: { isFeatured } });
  };

  const handleDeletePodcast = (podcastId: string) => {
    if (window.confirm('Are you sure you want to delete this podcast? This action cannot be undone.')) {
      deletePodcastMutation.mutate(podcastId);
    }
  };

  const handleBulkAction = () => {
    if (bulkAction && selectedPodcasts.length > 0) {
      bulkUpdatePodcastsMutation.mutate({
        podcastIds: selectedPodcasts,
        action: bulkAction,
      });
    }
  };

  const handleExportPodcasts = () => {
    // TODO: Implement export functionality
    alert('Export functionality will be implemented soon!');
  };

  const handleSavePodcast = async () => {
    try {
      const formDataToSend = new FormData();
      
      // Add form fields with correct backend field names
      const fieldMapping = {
        title: 'title',
        title_somali: 'title_somali',
        description: 'description',
        description_somali: 'description_somali',
        host: 'host',
        host_somali: 'host_somali',
        language: 'language',
        rss_feed_url: 'rss_feed_url',
        website_url: 'website_url',
        is_featured: 'is_featured',
        is_new_release: 'is_new_release',
        is_premium: 'is_premium',
        is_free: 'is_free'
      };

      Object.entries(formData).forEach(([key, value]) => {
        if (value !== undefined && value !== null && key !== 'selectedCategories') {
          const backendKey = fieldMapping[key as keyof typeof fieldMapping] || key;
          formDataToSend.append(backendKey, value.toString());
        }
      });

      // Add selected categories
      formData.selectedCategories.forEach((categoryId, index) => {
        formDataToSend.append(`categories[${index}]`, categoryId);
      });

      // Add files with correct field names for backend
      if (uploadedFiles.cover) {
        formDataToSend.append('coverImage', uploadedFiles.cover);
      }
      
      if (selectedPodcast) {
        // Update existing podcast
        await updatePodcastMutation.mutateAsync({ id: selectedPodcast.id, podcastData: formDataToSend });
      } else {
        // Create new podcast
        await createPodcastMutation.mutateAsync(formDataToSend);
      }
    } catch (error) {
      console.error('Error saving podcast:', error);
      
      if (error.response?.data?.code === 'INVALID_CATEGORIES') {
        alert(`Error: ${error.response.data.details}\n\nPlease select valid categories from the dropdown.`);
      } else if (error.response?.data?.error) {
        alert(`Error saving podcast: ${error.response.data.error}`);
      } else {
        alert(`Error saving podcast: ${error.message || 'Unknown error'}`);
      }
    }
  };

  const handleAddNewPodcast = () => {
    setSelectedPodcast(null);
    resetForm();
    setShowPodcastDialog(true);
  };

  if (error) {
    return (
      <Alert severity="error" sx={{ m: 2 }}>
        Failed to load podcasts: {error.message}
      </Alert>
    );
  }

  return (
    <Box sx={{ 
      p: isMobile ? 1 : 3, 
      minHeight: '100vh',
      overflow: 'auto'
    }}>
      <Box display="flex" justifyContent="space-between" alignItems="center" sx={{ mb: 3 }}>
        <Typography variant={isMobile ? "h5" : "h4"}>Podcast Management</Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={handleAddNewPodcast}
          size={isMobile ? "small" : "medium"}
        >
          {isMobile ? 'Add Podcast' : 'Add New Podcast'}
        </Button>
      </Box>

      {renderPodcastStats()}
      {renderFilters()}

      <Card sx={{ mt: 3 }}>
        <DataGrid
          key={dataGridKey}
          rows={podcastsData?.podcasts || []}
          columns={columns}
          loading={isLoading}
          checkboxSelection
          onRowSelectionModelChange={(newSelection) => setSelectedPodcasts(newSelection as string[])}
          rowSelectionModel={selectedPodcasts}
          getRowId={(row) => row.id}
          autoHeight
          pageSizeOptions={isMobile ? [10, 25] : [10, 25, 50, 100]}
          initialState={{
            pagination: {
              paginationModel: { page: 0, pageSize: isMobile ? 10 : 25 },
            },
          }}
          slots={{ toolbar: GridToolbar }}
          slotProps={{
            toolbar: {
              showQuickFilter: false,
            },
          }}
          sx={{
            '& .MuiDataGrid-root': {
              border: 'none',
            },
            '& .MuiDataGrid-cell': {
              borderBottom: '1px solid',
              borderColor: 'divider',
            },
            '& .MuiDataGrid-main': {
              overflow: 'auto',
            },
            '& .MuiDataGrid-virtualScroller': {
              overflow: 'auto',
            },
          }}
        />
      </Card>

      {renderBulkActionsDialog()}
      {renderPodcastDialog()}

      <Snackbar
        open={updatePodcastStatusMutation.isSuccess || bulkUpdatePodcastsMutation.isSuccess || 
              createPodcastMutation.isSuccess || updatePodcastMutation.isSuccess}
        autoHideDuration={6000}
        onClose={() => {}}
      >
        <Alert severity="success">
          {updatePodcastStatusMutation.isSuccess && 'Podcast status updated successfully!'}
          {bulkUpdatePodcastsMutation.isSuccess && 'Bulk operation completed successfully!'}
          {createPodcastMutation.isSuccess && 'Podcast created successfully!'}
          {updatePodcastMutation.isSuccess && 'Podcast updated successfully!'}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default PodcastsPage;
