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
  Collapse,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction
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
  Podcast as PodcastIcon,
  AudioFile as AudioIcon,
  Language as LanguageIcon,
  Category as CategoryIcon,
  CloudUpload as UploadIcon,
  Close as CloseIcon,
  ExpandMore as ExpandMoreIcon,
  ExpandLess as ExpandLessIcon,
  PlayArrow as PlayIcon,
  Headphones as HeadphonesIcon,
  Schedule as ScheduleIcon,
  Timer as TimerIcon,
  VolumeUp as VolumeIcon,
  Description as DescriptionIcon,
  BookmarkBorder as BookmarkIcon
} from '@mui/icons-material';
import { DataGrid, GridColDef, GridActionsCellItem, GridToolbar } from '@mui/x-data-grid';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { 
  getPodcastEpisodes,
  createPodcastEpisode,
  updatePodcastEpisode,
  deletePodcastEpisode,
  getPodcast
} from '../../services/adminAPI';
import { useNavigate, useParams } from 'react-router-dom';
import { format } from 'date-fns';
import { useDropzone } from 'react-dropzone';

interface Episode {
  id: string;
  podcast_id: string;
  title: string;
  title_somali: string;
  description: string;
  description_somali: string;
  episode_number: number;
  season_number: number;
  duration?: number;
  audio_url?: string;
  transcript_url?: string;
  transcript_content?: string;
  show_notes?: any;
  chapters?: any;
  rating?: number;
  play_count: number;
  download_count: number;
  is_featured: boolean;
  is_premium: boolean;
  is_free: boolean;
  published_at: string;
  created_at: string;
  updated_at: string;
}

interface EpisodeFormData {
  title: string;
  title_somali: string;
  description: string;
  description_somali: string;
  episode_number: number;
  season_number: number;
  duration?: number;
  transcript_content: string;
  show_notes: string;
  chapters: string;
  is_featured: boolean;
  is_premium: boolean;
  is_free: boolean;
  published_at: string;
}

const PodcastEpisodesPage: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const navigate = useNavigate();
  const { podcastId } = useParams<{ podcastId: string }>();
  const queryClient = useQueryClient();
  
  // State
  const [searchTerm, setSearchTerm] = useState('');
  const [seasonFilter, setSeasonFilter] = useState<string>('all');
  const [selectedEpisodes, setSelectedEpisodes] = useState<string[]>([]);
  const [bulkAction, setBulkAction] = useState<string>('');
  const [showBulkDialog, setShowBulkDialog] = useState(false);
  const [showEpisodeDialog, setShowEpisodeDialog] = useState(false);
  const [selectedEpisode, setSelectedEpisode] = useState<Episode | null>(null);
  const [activeTab, setActiveTab] = useState(0);
  const [activeStep, setActiveStep] = useState(0);
  const [expandedFilters, setExpandedFilters] = useState(false);
  const [dataGridKey, setDataGridKey] = useState(0);
  const [podcast, setPodcast] = useState<any>(null);

  // Force DataGrid to re-render when screen size changes
  useEffect(() => {
    const handleResize = () => {
      setDataGridKey(prev => prev + 1);
    };

    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  // Form state
  const [formData, setFormData] = useState<EpisodeFormData>({
    title: '',
    title_somali: '',
    description: '',
    description_somali: '',
    episode_number: 1,
    season_number: 1,
    duration: undefined,
    transcript_content: '',
    show_notes: '',
    chapters: '',
    is_featured: false,
    is_premium: false,
    is_free: true,
    published_at: new Date().toISOString().split('T')[0]
  });

  // File upload state
  const [uploadedFiles, setUploadedFiles] = useState<{
    audio?: File;
  }>({});

  // Fetch podcast info
  useEffect(() => {
    if (podcastId) {
      getPodcast(podcastId).then(setPodcast).catch(console.error);
    }
  }, [podcastId]);

  // Fetch episodes with enhanced query
  const { data: episodesData, isLoading, error } = useQuery({
    queryKey: ['podcastEpisodes', podcastId, { search: searchTerm, season: seasonFilter }],
    queryFn: () => getPodcastEpisodes(podcastId!, { 
      search: searchTerm, 
      season: seasonFilter === 'all' ? undefined : seasonFilter
    }),
    enabled: !!podcastId,
    staleTime: 30000,
  });

  // Force DataGrid to re-render after initial load to fix scroll issues
  useEffect(() => {
    const timer = setTimeout(() => {
      setDataGridKey(prev => prev + 1);
    }, 100);

    return () => clearTimeout(timer);
  }, [episodesData]);

  // Mutations
  const createEpisodeMutation = useMutation({
    mutationFn: (episodeData: FormData) => createPodcastEpisode(podcastId!, episodeData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['podcastEpisodes'] });
      setShowEpisodeDialog(false);
      resetForm();
    },
  });

  const updateEpisodeMutation = useMutation({
    mutationFn: (data: { episodeId: string; episodeData: FormData }) => 
      updatePodcastEpisode(podcastId!, data.episodeId, data.episodeData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['podcastEpisodes'] });
      setShowEpisodeDialog(false);
      resetForm();
    },
  });

  const deleteEpisodeMutation = useMutation({
    mutationFn: (episodeId: string) => deletePodcastEpisode(podcastId!, episodeId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['podcastEpisodes'] });
    },
  });

  // File dropzone
  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop: (acceptedFiles) => {
      // Handle file uploads
      acceptedFiles.forEach(file => {
        if (file.type.startsWith('audio/')) {
          setUploadedFiles(prev => ({ ...prev, audio: file }));
        }
      });
    },
    accept: {
      'audio/*': ['.mp3', '.wav', '.m4a', '.aac', '.ogg']
    }
  });

  // Enhanced columns with responsive design
  const columns: GridColDef[] = useMemo(() => [
    {
      field: 'episode_number',
      headerName: 'Episode',
      width: isMobile ? 80 : 100,
      renderCell: (params) => (
        <Box display="flex" alignItems="center">
          <PlayIcon sx={{ mr: 0.5, fontSize: 16 }} />
          <Typography variant="body2" fontWeight="medium">
            {params.row.episode_number}
          </Typography>
        </Box>
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
          {params.row.season_number > 1 && (
            <Chip 
              label={`S${params.row.season_number}`} 
              size="small" 
              color="secondary" 
              variant="outlined"
              sx={{ fontSize: '0.6rem', height: 16, mt: 0.5 }}
            />
          )}
        </Box>
      ),
    },
    {
      field: 'duration',
      headerName: 'Duration',
      width: isMobile ? 80 : 120,
      renderCell: (params) => (
        <Box display="flex" alignItems="center">
          <TimerIcon sx={{ mr: 0.5, fontSize: 16 }} />
          <Typography variant="body2" noWrap>
            {params.row.duration ? `${Math.floor(params.row.duration / 60)}:${(params.row.duration % 60).toString().padStart(2, '0')}` : 'N/A'}
          </Typography>
        </Box>
      ),
    },
    {
      field: 'audio',
      headerName: 'Audio',
      width: isMobile ? 80 : 120,
      renderCell: (params) => (
        <Box display="flex" alignItems="center">
          <AudioIcon sx={{ mr: 0.5, fontSize: 16 }} />
          <Typography variant="body2" noWrap>
            {params.row.audio_url ? 'Available' : 'Missing'}
          </Typography>
        </Box>
      ),
    },
    {
      field: 'stats',
      headerName: 'Stats',
      width: isMobile ? 100 : 150,
      renderCell: (params) => (
        <Box>
          <Typography variant="caption" display="block">
            {params.row.play_count || 0} plays
          </Typography>
          <Typography variant="caption" display="block">
            {params.row.download_count || 0} downloads
          </Typography>
        </Box>
      ),
    },
    {
      field: 'rating',
      headerName: 'Rating',
      width: isMobile ? 100 : 140,
      renderCell: (params) => (
        <Box>
          <Rating value={parseFloat(params.row.rating) || 0} readOnly size="small" />
          <Typography variant="caption" display="block">
            {params.row.rating || 'No rating'}
          </Typography>
        </Box>
      ),
    },
    {
      field: 'features',
      headerName: 'Features',
      width: isMobile ? 100 : 150,
      renderCell: (params) => (
        <Box>
          {params.row.is_featured && (
            <Chip label="Featured" color="success" size="small" sx={{ mb: 0.5 }} />
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
      field: 'publishedAt',
      headerName: 'Published',
      width: isMobile ? 100 : 130,
      valueGetter: (params) => format(new Date(params.row.published_at), 'MMM dd, yyyy'),
    },
    {
      field: 'actions',
      headerName: 'Actions',
      width: isMobile ? 120 : 180,
      type: 'actions',
      getActions: (params) => [
        <GridActionsCellItem
          icon={<ViewIcon />}
          label="View Episode"
          onClick={() => handleViewEpisode(params.row)}
        />,
        <GridActionsCellItem
          icon={<EditIcon />}
          label="Edit Episode"
          onClick={() => handleEditEpisode(params.row)}
        />,
        <GridActionsCellItem
          icon={<DeleteIcon />}
          label="Delete Episode"
          onClick={() => handleDeleteEpisode(params.row.id)}
        />,
      ],
    },
  ], [isMobile]);

  // Enhanced episode form dialog with stepper
  const renderEpisodeDialog = () => (
    <Dialog 
      open={showEpisodeDialog} 
      onClose={() => setShowEpisodeDialog(false)} 
      maxWidth="lg" 
      fullWidth
      fullScreen={isMobile}
    >
      <DialogTitle>
        {selectedEpisode ? `Edit Episode: ${selectedEpisode.title}` : 'Add New Episode'}
        {isMobile && (
          <IconButton
            aria-label="close"
            onClick={() => setShowEpisodeDialog(false)}
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
            <StepLabel>Audio & Media</StepLabel>
          </Step>
          <Step>
            <StepLabel>Content & Transcript</StepLabel>
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
            <Grid item xs={6} sm={3}>
              <TextField
                fullWidth
                label="Episode Number *"
                type="number"
                value={formData.episode_number}
                onChange={(e) => setFormData(prev => ({ ...prev, episode_number: parseInt(e.target.value) || 1 }))}
                required
                inputProps={{ min: 1 }}
              />
            </Grid>
            <Grid item xs={6} sm={3}>
              <TextField
                fullWidth
                label="Season Number"
                type="number"
                value={formData.season_number}
                onChange={(e) => setFormData(prev => ({ ...prev, season_number: parseInt(e.target.value) || 1 }))}
                inputProps={{ min: 1 }}
              />
            </Grid>
            <Grid item xs={6} sm={3}>
              <TextField
                fullWidth
                label="Duration (minutes)"
                type="number"
                value={formData.duration || ''}
                onChange={(e) => setFormData(prev => ({ ...prev, duration: parseInt(e.target.value) || undefined }))}
                inputProps={{ min: 0 }}
              />
            </Grid>
            <Grid item xs={6} sm={3}>
              <TextField
                fullWidth
                label="Published Date"
                type="date"
                value={formData.published_at}
                onChange={(e) => setFormData(prev => ({ ...prev, published_at: e.target.value }))}
                InputLabelProps={{ shrink: true }}
              />
            </Grid>
          </Grid>
        )}

        {/* Step 2: Audio & Media */}
        {activeStep === 1 && (
          <Grid container spacing={2}>
            <Grid item xs={12}>
              <Typography variant="h6" gutterBottom>Audio File Upload</Typography>
              <Typography variant="body2" color="textSecondary" sx={{ mb: 2 }}>
                Drag and drop audio file here or click to select
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
                <VolumeIcon sx={{ fontSize: 48, color: 'primary.main', mb: 1 }} />
                <Typography variant="h6" gutterBottom>
                  {isDragActive ? 'Drop audio file here' : 'Upload Audio File'}
                </Typography>
                <Typography variant="body2" color="textSecondary">
                  Supported: Audio files (MP3, WAV, M4A, AAC, OGG)
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
              {selectedEpisode && (
                <Grid container spacing={2} sx={{ mt: 2 }}>
                  <Grid item xs={12}>
                    <TextField
                      fullWidth
                      label="Audio URL"
                      defaultValue={selectedEpisode.audio_url}
                      helperText="Current audio file URL"
                    />
                  </Grid>
                </Grid>
              )}
            </Grid>
          </Grid>
        )}

        {/* Step 3: Content & Transcript */}
        {activeStep === 2 && (
          <Grid container spacing={2}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                multiline
                rows={6}
                label="Transcript Content"
                value={formData.transcript_content}
                onChange={(e) => setFormData(prev => ({ ...prev, transcript_content: e.target.value }))}
                placeholder="Enter the full transcript of the episode..."
                helperText="Optional: Full transcript for accessibility and search"
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                multiline
                rows={4}
                label="Show Notes (JSON)"
                value={formData.show_notes}
                onChange={(e) => setFormData(prev => ({ ...prev, show_notes: e.target.value }))}
                placeholder='{"links": [], "resources": [], "timestamps": []}'
                helperText="Optional: Show notes in JSON format"
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                multiline
                rows={4}
                label="Chapters (JSON)"
                value={formData.chapters}
                onChange={(e) => setFormData(prev => ({ ...prev, chapters: e.target.value }))}
                placeholder='[{"title": "Introduction", "start": 0, "end": 300}]'
                helperText="Optional: Chapter markers in JSON format"
              />
            </Grid>
          </Grid>
        )}

        {/* Step 4: Settings & Features */}
        {activeStep === 3 && (
          <Grid container spacing={2}>
            <Grid item xs={12}>
              <Typography variant="h6" gutterBottom>Episode Features & Settings</Typography>
            </Grid>
            <Grid item xs={12} sm={4}>
              <FormControlLabel
                control={
                  <Switch 
                    checked={formData.is_featured}
                    onChange={(e) => setFormData(prev => ({ ...prev, is_featured: e.target.checked }))}
                  />
                }
                label="Featured Episode"
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
                label="Free Episode"
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
                onClick={handleSaveEpisode}
                disabled={!isFormValid()}
              >
                {selectedEpisode ? 'Update Episode' : 'Create Episode'}
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
            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                size="small"
                placeholder="Search episodes..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                InputProps={{
                  startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />,
                }}
              />
            </Grid>
            <Grid item xs={6} md={2}>
              <FormControl fullWidth size="small">
                <InputLabel>Season</InputLabel>
                <Select
                  value={seasonFilter}
                  onChange={(e) => setSeasonFilter(e.target.value)}
                  label="Season"
                >
                  <MenuItem value="all">All Seasons</MenuItem>
                  <MenuItem value="1">Season 1</MenuItem>
                  <MenuItem value="2">Season 2</MenuItem>
                  <MenuItem value="3">Season 3</MenuItem>
                  <MenuItem value="4">Season 4</MenuItem>
                  <MenuItem value="5">Season 5</MenuItem>
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
                  disabled={selectedEpisodes.length === 0}
                  fullWidth={isMobile}
                >
                  Bulk Actions ({selectedEpisodes.length})
                </Button>
                <Button
                  variant="outlined"
                  size="small"
                  startIcon={<RefreshIcon />}
                  onClick={() => queryClient.invalidateQueries({ queryKey: ['podcastEpisodes'] })}
                  fullWidth={isMobile}
                >
                  Refresh
                </Button>
              </Box>
            </Grid>
            <Grid item xs={12} md={3}>
              <Button
                variant="contained"
                startIcon={<AddIcon />}
                onClick={handleAddNewEpisode}
                fullWidth={isMobile}
              >
                Add Episode
              </Button>
            </Grid>
          </Grid>
        </Collapse>
      </CardContent>
    </Card>
  );

  // Form validation
  const isStepValid = (step: number) => {
    switch (step) {
      case 0:
        return formData.title && formData.title_somali && formData.description && 
               formData.description_somali && formData.episode_number > 0;
      case 1:
        return true; // Optional files
      case 2:
        return true; // Optional content
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
      episode_number: (episodesData?.episodes?.length || 0) + 1,
      season_number: 1,
      duration: undefined,
      transcript_content: '',
      show_notes: '',
      chapters: '',
      is_featured: false,
      is_premium: false,
      is_free: true,
      published_at: new Date().toISOString().split('T')[0]
    });
    setUploadedFiles({});
    setActiveStep(0);
  };

  // Event handlers
  const handleViewEpisode = (episode: Episode) => {
    setSelectedEpisode(episode);
    setShowEpisodeDialog(true);
    setActiveStep(0);
  };

  const handleEditEpisode = (episode: Episode) => {
    setSelectedEpisode(episode);
    setFormData({
      title: episode.title,
      title_somali: episode.title_somali,
      description: episode.description,
      description_somali: episode.description_somali,
      episode_number: episode.episode_number,
      season_number: episode.season_number,
      duration: episode.duration,
      transcript_content: episode.transcript_content || '',
      show_notes: episode.show_notes ? JSON.stringify(episode.show_notes, null, 2) : '',
      chapters: episode.chapters ? JSON.stringify(episode.chapters, null, 2) : '',
      is_featured: Boolean(episode.is_featured),
      is_premium: Boolean(episode.is_premium),
      is_free: Boolean(episode.is_free),
      published_at: episode.published_at.split('T')[0]
    });
    setShowEpisodeDialog(true);
    setActiveStep(0);
  };

  const handleDeleteEpisode = (episodeId: string) => {
    if (window.confirm('Are you sure you want to delete this episode? This action cannot be undone.')) {
      deleteEpisodeMutation.mutate(episodeId);
    }
  };

  const handleSaveEpisode = async () => {
    try {
      const formDataToSend = new FormData();
      
      // Add form fields with correct backend field names
      const fieldMapping = {
        title: 'title',
        title_somali: 'title_somali',
        description: 'description',
        description_somali: 'description_somali',
        episode_number: 'episode_number',
        season_number: 'season_number',
        duration: 'duration',
        transcript_content: 'transcript_content',
        show_notes: 'show_notes',
        chapters: 'chapters',
        is_featured: 'is_featured',
        is_premium: 'is_premium',
        is_free: 'is_free',
        published_at: 'published_at'
      };

      Object.entries(formData).forEach(([key, value]) => {
        if (value !== undefined && value !== null) {
          const backendKey = fieldMapping[key as keyof typeof fieldMapping] || key;
          formDataToSend.append(backendKey, value.toString());
        }
      });

      // Add files with correct field names for backend
      if (uploadedFiles.audio) {
        formDataToSend.append('audioFile', uploadedFiles.audio);
      }
      
      if (selectedEpisode) {
        // Update existing episode
        await updateEpisodeMutation.mutateAsync({ episodeId: selectedEpisode.id, episodeData: formDataToSend });
      } else {
        // Create new episode
        await createEpisodeMutation.mutateAsync(formDataToSend);
      }
    } catch (error) {
      console.error('Error saving episode:', error);
      
      if (error.response?.data?.error) {
        alert(`Error saving episode: ${error.response.data.error}`);
      } else {
        alert(`Error saving episode: ${error.message || 'Unknown error'}`);
      }
    }
  };

  const handleAddNewEpisode = () => {
    setSelectedEpisode(null);
    resetForm();
    setShowEpisodeDialog(true);
  };

  if (!podcastId) {
    return (
      <Alert severity="error" sx={{ m: 2 }}>
        No podcast ID provided
      </Alert>
    );
  }

  if (error) {
    return (
      <Alert severity="error" sx={{ m: 2 }}>
        Failed to load episodes: {error.message}
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
        <Box>
          <Typography variant={isMobile ? "h5" : "h4"}>Episode Management</Typography>
          {podcast && (
            <Typography variant="body1" color="textSecondary">
              {podcast.title}
            </Typography>
          )}
        </Box>
        <Button
          variant="outlined"
          onClick={() => navigate('/admin/podcasts')}
          size={isMobile ? "small" : "medium"}
        >
          Back to Podcasts
        </Button>
      </Box>

      {renderFilters()}

      <Card sx={{ mt: 3 }}>
        <DataGrid
          key={dataGridKey}
          rows={episodesData?.episodes || []}
          columns={columns}
          loading={isLoading}
          checkboxSelection
          onRowSelectionModelChange={(newSelection) => setSelectedEpisodes(newSelection as string[])}
          rowSelectionModel={selectedEpisodes}
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

      {renderEpisodeDialog()}

      <Snackbar
        open={createEpisodeMutation.isSuccess || updateEpisodeMutation.isSuccess}
        autoHideDuration={6000}
        onClose={() => {}}
      >
        <Alert severity="success">
          {createEpisodeMutation.isSuccess && 'Episode created successfully!'}
          {updateEpisodeMutation.isSuccess && 'Episode updated successfully!'}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default PodcastEpisodesPage;
