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
  Book as BookIcon,
  AudioFile as AudioIcon,
  PictureAsPdf as PdfIcon,
  TrendingUp as TrendingIcon,
  Star as StarIcon,
  Language as LanguageIcon,
  Category as CategoryIcon,
  CloudUpload as UploadIcon,
  Close as CloseIcon,
  ExpandMore as ExpandMoreIcon,
  ExpandLess as ExpandLessIcon
} from '@mui/icons-material';
import { DataGrid, GridColDef, GridActionsCellItem, GridToolbar } from '@mui/x-data-grid';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { 
  getBooks, 
  getBookStats, 
  updateBookStatus, 
  bulkUpdateBooks,
  deleteBook,
  createBook,
  updateBook,
  getBookCategories,
  getBook
} from '../../services/adminAPI';
import { useNavigate } from 'react-router-dom';
import { format } from 'date-fns';
import { useDropzone } from 'react-dropzone';

interface Book {
  id: string;
  title: string;
  title_somali: string;
  description: string;
  description_somali: string;
  authors: string;
  authors_somali: string;
  language: 'en' | 'so' | 'ar';
  format: 'ebook' | 'audiobook' | 'both';
  cover_image_url?: string;
  audio_url?: string;
  ebook_content?: string;
  duration?: number;
  page_count?: number;
  rating?: number;
  review_count?: number;
  is_featured: boolean;
  is_new_release: boolean;
  is_premium: boolean;
  metadata?: any;
  created_at: string;
  updated_at: string;
  categories?: string[];
  categoryNames?: string[];
  categoryNamesSomali?: string[];
}

interface BookStats {
  totalBooks: number;
  featuredBooks: number;
  newReleases: number;
  premiumBooks: number;
  totalDownloads: number;
  averageRating: number;
  booksByLanguage: Record<string, number>;
  booksByFormat: Record<string, number>;
}

interface BookFormData {
  title: string;
  title_somali: string;
  description: string;
  description_somali: string;
  authors: string;
  authors_somali: string;
  selectedCategories: string[];  // Changed from genre to selectedCategories
  language: 'en' | 'so' | 'ar';
  format: 'ebook' | 'audiobook' | 'both';
  duration?: number;
  page_count?: number;
  is_featured: boolean;
  is_new_release: boolean;
  is_premium: boolean;
  ebook_content: string;  // New field for text content
}

const BooksPage: React.FC = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  
  // State
  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');
  const [languageFilter, setLanguageFilter] = useState<string>('all');
  const [formatFilter, setFormatFilter] = useState<string>('all');
  const [featuredFilter, setFeaturedFilter] = useState<string>('all');
  const [selectedBooks, setSelectedBooks] = useState<string[]>([]);
  const [bulkAction, setBulkAction] = useState<string>('');
  const [showBulkDialog, setShowBulkDialog] = useState(false);
  const [showBookDialog, setShowBookDialog] = useState(false);
  const [selectedBook, setSelectedBook] = useState<Book | null>(null);
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
  const [formData, setFormData] = useState<BookFormData>({
    title: '',
    title_somali: '',
    description: '',
    description_somali: '',
    authors: '',
    authors_somali: '',
    selectedCategories: [],  // Changed from genre to selectedCategories
    language: 'en',
    format: 'ebook',
    duration: undefined,
    page_count: undefined,
    is_featured: false,
    is_new_release: false,
    is_premium: false,
    ebook_content: ''  // Initialize ebook content field
  });


  // File upload state
  const [uploadedFiles, setUploadedFiles] = useState<{
    cover?: File;
    audio?: File;
  }>({});

  // Fetch books with enhanced query
  const { data: booksData, isLoading, error } = useQuery({
    queryKey: ['books', { search: searchTerm, category: categoryFilter, language: languageFilter, format: formatFilter, featured: featuredFilter }],
    queryFn: () => getBooks({ 
      search: searchTerm, 
      category: categoryFilter === 'all' ? undefined : categoryFilter,
      language: languageFilter === 'all' ? undefined : languageFilter,
      format: formatFilter === 'all' ? undefined : formatFilter,
      featured: featuredFilter === 'all' ? undefined : featuredFilter === 'true'
    }),
    staleTime: 30000,
  });

  // Fetch book statistics
  const { data: bookStats } = useQuery({
    queryKey: ['bookStats'],
    queryFn: () => getBookStats(),
    staleTime: 60000,
  });

  // Fetch categories for category filter
  const { data: categories } = useQuery({
    queryKey: ['bookCategories'],
    queryFn: () => getBookCategories(),
    staleTime: 300000, // 5 minutes
  });

  // Force DataGrid to re-render after initial load to fix scroll issues
  useEffect(() => {
    const timer = setTimeout(() => {
      setDataGridKey(prev => prev + 1);
    }, 100);

    return () => clearTimeout(timer);
  }, [booksData]);

  // Mutations
  const updateBookStatusMutation = useMutation({
    mutationFn: ({ id, statusData }: { id: string; statusData: any }) => updateBookStatus(id, statusData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['books'] });
      queryClient.invalidateQueries({ queryKey: ['bookStats'] });
    },
  });

  const bulkUpdateBooksMutation = useMutation({
    mutationFn: bulkUpdateBooks,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['books'] });
      queryClient.invalidateQueries({ queryKey: ['bookStats'] });
      setSelectedBooks([]);
      setShowBulkDialog(false);
    },
  });

  const deleteBookMutation = useMutation({
    mutationFn: deleteBook,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['books'] });
      queryClient.invalidateQueries({ queryKey: ['bookStats'] });
    },
  });

  const createBookMutation = useMutation({
    mutationFn: createBook,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['books'] });
      queryClient.invalidateQueries({ queryKey: ['bookStats'] });
      setShowBookDialog(false);
      resetForm();
    },
  });

  const updateBookMutation = useMutation({
    mutationFn: (data: { id: string; bookData: FormData }) => updateBook(data.id, data.bookData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['books'] });
      queryClient.invalidateQueries({ queryKey: ['bookStats'] });
      setShowBookDialog(false);
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
        } else if (file.type.startsWith('audio/')) {
          setUploadedFiles(prev => ({ ...prev, audio: file }));
        }
      });
    },
    accept: {
      'image/*': ['.jpeg', '.jpg', '.png', '.webp', '.gif'],
      'audio/*': ['.mp3', '.wav', '.m4a', '.aac', '.ogg', '.flac', '.webm']
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
          <BookIcon />
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
      field: 'authors',
      headerName: 'Authors',
      width: isMobile ? 120 : 180,
      renderCell: (params) => (
        <Typography variant="body2" noWrap>
          {params.row.authors}
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
      field: 'format',
      headerName: 'Format',
      width: isMobile ? 80 : 120,
      renderCell: (params) => (
        <Box display="flex" alignItems="center">
          {params.row.format === 'audiobook' ? <AudioIcon /> : <PdfIcon />}
          <Typography variant="body2" sx={{ ml: 0.5 }} noWrap>
            {params.row.format}
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
            <Chip label="Premium" color="info" size="small" />
          )}
        </Box>
      ),
    },
    {
      field: 'stats',
      headerName: 'Stats',
      width: isMobile ? 100 : 120,
      renderCell: (params) => (
        <Box>
          {params.row.page_count && (
            <Typography variant="caption" display="block">
              {params.row.page_count} pages
            </Typography>
          )}
          {params.row.duration && (
            <Typography variant="caption" display="block">
              {Math.round(params.row.duration / 60)} min
            </Typography>
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
          label="View Book"
          onClick={() => handleViewBook(params.row)}
        />,
        <GridActionsCellItem
          icon={<EditIcon />}
          label="Edit Book"
          onClick={() => handleEditBook(params.row)}
        />,
        <GridActionsCellItem
          icon={params.row.is_featured ? <BlockIcon /> : <StarIcon />}
          label={params.row.is_featured ? 'Unfeature' : 'Feature'}
          onClick={() => handleToggleFeatured(params.row.id, !params.row.is_featured)}
        />,
        <GridActionsCellItem
          icon={<DeleteIcon />}
          label="Delete Book"
          onClick={() => handleDeleteBook(params.row.id)}
        />,
      ],
    },
  ], [isMobile]);

  // Enhanced book statistics cards with responsive design
  const renderBookStats = () => (
    <Grid container spacing={isMobile ? 2 : 3} sx={{ mb: 3 }}>
      <Grid item xs={6} sm={6} md={3}>
        <Card>
          <CardContent sx={{ p: isMobile ? 1.5 : 2 }}>
            <Box display="flex" alignItems="center">
              <BookIcon color="primary" sx={{ mr: 1, fontSize: isMobile ? 30 : 40 }} />
              <Box>
                <Typography variant={isMobile ? "h5" : "h4"}>{bookStats?.totalBooks || 0}</Typography>
                <Typography variant="body2" color="textSecondary" noWrap>Total Books</Typography>
              </Box>
            </Box>
          </CardContent>
        </Card>
      </Grid>
      <Grid item xs={6} sm={6} md={3}>
        <Card>
          <CardContent sx={{ p: isMobile ? 1.5 : 2 }}>
            <Box display="flex" alignItems="center">
              <StarIcon color="success" sx={{ mr: 1, fontSize: isMobile ? 30 : 40 }} />
              <Box>
                <Typography variant={isMobile ? "h5" : "h4"}>{bookStats?.featuredBooks || 0}</Typography>
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
              <TrendingIcon color="warning" sx={{ mr: 1, fontSize: isMobile ? 30 : 40 }} />
              <Box>
                <Typography variant={isMobile ? "h5" : "h4"}>{bookStats?.newReleases || 0}</Typography>
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
              <AudioIcon color="info" sx={{ mr: 1, fontSize: isMobile ? 30 : 40 }} />
              <Box>
                <Typography variant={isMobile ? "h5" : "h4"}>{bookStats?.totalDownloads || 0}</Typography>
                <Typography variant="body2" color="textSecondary" noWrap>Downloads</Typography>
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
                placeholder="Search books..."
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
                <InputLabel>Format</InputLabel>
                <Select
                  value={formatFilter}
                  onChange={(e) => setFormatFilter(e.target.value)}
                  label="Format"
                >
                  <MenuItem value="all">All Formats</MenuItem>
                  <MenuItem value="ebook">E-Book</MenuItem>
                  <MenuItem value="audiobook">Audio</MenuItem>
                  <MenuItem value="both">Both</MenuItem>
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
                  disabled={selectedBooks.length === 0}
                  fullWidth={isMobile}
                >
                  Bulk Actions ({selectedBooks.length})
                </Button>
                <Button
                  variant="outlined"
                  size="small"
                  startIcon={<DownloadIcon />}
                  onClick={() => handleExportBooks()}
                  fullWidth={isMobile}
                >
                  Export
                </Button>
                <Button
                  variant="outlined"
                  size="small"
                  startIcon={<RefreshIcon />}
                  onClick={() => queryClient.invalidateQueries({ queryKey: ['books'] })}
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

  // Enhanced book form dialog with stepper and all required fields
  const renderBookDialog = () => (
    <Dialog 
      open={showBookDialog} 
      onClose={() => setShowBookDialog(false)} 
      maxWidth="lg" 
      fullWidth
      fullScreen={isMobile}
    >
      <DialogTitle>
        {selectedBook ? `Edit Book: ${selectedBook.title}` : 'Add New Book'}
        {isMobile && (
          <IconButton
            aria-label="close"
            onClick={() => setShowBookDialog(false)}
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
            <StepLabel>Content Details</StepLabel>
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
                label="Authors (English) *"
                value={formData.authors}
                onChange={(e) => setFormData(prev => ({ ...prev, authors: e.target.value }))}
                placeholder="Enter author names separated by commas"
                required
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Authors (Somali) *"
                value={formData.authors_somali}
                onChange={(e) => setFormData(prev => ({ ...prev, authors_somali: e.target.value }))}
                placeholder="Enter author names separated by commas"
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
                  Select one or more categories for this book
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
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth required>
                <InputLabel>Format</InputLabel>
                <Select
                  value={formData.format}
                  onChange={(e) => setFormData(prev => ({ ...prev, format: e.target.value as 'ebook' | 'audiobook' | 'both' }))}
                  label="Format"
                >
                  <MenuItem value="ebook">E-Book</MenuItem>
                  <MenuItem value="audiobook">Audio Book</MenuItem>
                  <MenuItem value="both">Both</MenuItem>
                </Select>
              </FormControl>
            </Grid>
          </Grid>
        )}

        {/* Step 2: Content Details */}
        {activeStep === 1 && (
          <Grid container spacing={2}>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Page Count"
                type="number"
                value={formData.page_count || ''}
                onChange={(e) => setFormData(prev => ({ ...prev, page_count: e.target.value ? parseInt(e.target.value) : undefined }))}
                InputProps={{
                  endAdornment: <InputAdornment position="end">pages</InputAdornment>,
                }}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Duration"
                type="number"
                value={formData.duration || ''}
                onChange={(e) => setFormData(prev => ({ ...prev, duration: e.target.value ? parseInt(e.target.value) : undefined }))}
                InputProps={{
                  endAdornment: <InputAdornment position="end">minutes</InputAdornment>,
                }}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="E-Book Content"
                multiline
                rows={6}
                value={formData.ebook_content}
                onChange={(e) => setFormData(prev => ({ ...prev, ebook_content: e.target.value }))}
                placeholder="Enter the full text content of the e-book here..."
                helperText="The complete text content of the book for reading"
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Metadata (JSON)"
                multiline
                rows={3}
                value={JSON.stringify(formData.metadata || {}, null, 2)}
                onChange={(e) => {
                  try {
                    const metadata = JSON.parse(e.target.value);
                    setFormData(prev => ({ ...prev, metadata }));
                  } catch {
                    // Invalid JSON, ignore
                  }
                }}
                placeholder='{"publisher": "Publisher Name", "isbn": "1234567890", "year": 2024}'
                helperText="Optional: Additional book metadata in JSON format"
              />
            </Grid>
          </Grid>
        )}

        {/* Step 3: Files & Media */}
        {activeStep === 2 && (
          <Grid container spacing={2}>
            <Grid item xs={12}>
              <Typography variant="h6" gutterBottom>File Uploads</Typography>
              <Typography variant="body2" color="textSecondary" sx={{ mb: 2 }}>
                Drag and drop files here or click to select
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
                  {isDragActive ? 'Drop files here' : 'Upload Files'}
                </Typography>
                <Typography variant="body2" color="textSecondary">
                  Supported: Images (JPG, PNG, WebP, GIF), Audio (MP3, WAV, M4A, AAC, OGG, FLAC)
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
              {selectedBook && (
                <Grid container spacing={2} sx={{ mt: 2 }}>
                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="Cover Image URL"
                      defaultValue={selectedBook.cover_image_url}
                      helperText="Current cover image URL"
                    />
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <TextField
                      fullWidth
                      label="Audio URL"
                      defaultValue={selectedBook.audio_url}
                      helperText="Current audio file URL"
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
              <Typography variant="h6" gutterBottom>Book Features & Settings</Typography>
            </Grid>
            <Grid item xs={12} sm={4}>
              <FormControlLabel
                control={
                  <Switch 
                    checked={formData.is_featured}
                    onChange={(e) => setFormData(prev => ({ ...prev, is_featured: e.target.checked }))}
                  />
                }
                label="Featured Book"
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
                onClick={handleSaveBook}
                disabled={!isFormValid()}
              >
                {selectedBook ? 'Update Book' : 'Create Book'}
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
          Apply actions to {selectedBooks.length} selected books
        </Typography>
        <FormControl fullWidth sx={{ mb: 2 }}>
          <InputLabel>Action</InputLabel>
          <Select
            value={bulkAction}
            onChange={(e) => setBulkAction(e.target.value)}
            label="Action"
          >
            <MenuItem value="feature">Feature Books</MenuItem>
            <MenuItem value="unfeature">Unfeature Books</MenuItem>
            <MenuItem value="markNew">Mark as New Release</MenuItem>
            <MenuItem value="markPremium">Mark as Premium</MenuItem>
            <MenuItem value="delete">Delete Books</MenuItem>
          </Select>
        </FormControl>
        {bulkAction === 'delete' && (
          <Alert severity="warning">
            This action cannot be undone. All selected books will be permanently deleted.
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
               formData.description_somali && formData.authors && formData.authors_somali && 
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
      authors: '',
      authors_somali: '',
      selectedCategories: [],
      language: 'en',
      format: 'ebook',
      duration: undefined,
      page_count: undefined,
      is_featured: false,
      is_new_release: false,
      is_premium: false,
      ebook_content: ''
    });
    setUploadedFiles({});
    setActiveStep(0);
  };

  // Event handlers
  const handleViewBook = (book: Book) => {
    setSelectedBook(book);
    setShowBookDialog(true);
    setActiveStep(0);
  };

  const handleEditBook = async (book: Book) => {
    // Fetch the complete book data including ebook content
    try {
      const completeBookData = await getBook(book.id);
      
      setSelectedBook(completeBookData || book);
      setFormData({
        title: completeBookData?.title || book.title,
        title_somali: completeBookData?.title_somali || book.title_somali,
        description: completeBookData?.description || book.description,
        description_somali: completeBookData?.description_somali || book.description_somali,
        authors: completeBookData?.authors || book.authors,
        authors_somali: completeBookData?.authors_somali || book.authors_somali,
        selectedCategories: completeBookData?.categories || book.categories || [],
        language: completeBookData?.language || book.language,
        format: completeBookData?.format || book.format,
        duration: completeBookData?.duration || book.duration,
        page_count: completeBookData?.page_count || book.page_count,
        is_featured: Boolean(completeBookData?.is_featured ?? book.is_featured),
        is_new_release: Boolean(completeBookData?.is_new_release ?? book.is_new_release),
        is_premium: Boolean(completeBookData?.is_premium ?? book.is_premium),
        ebook_content: completeBookData?.ebook_content || book.ebook_content || ''
      });
      
    } catch (error) {
      console.error('Error fetching complete book data:', error);
      // Fallback to using the book data from the list
      setSelectedBook(book);
      setFormData({
        title: book.title,
        title_somali: book.title_somali,
        description: book.description,
        description_somali: book.description_somali,
        authors: book.authors,
        authors_somali: book.authors_somali,
        selectedCategories: book.categories || [],
        language: book.language,
        format: book.format,
        duration: book.duration,
        page_count: book.page_count,
        is_featured: Boolean(book.is_featured),
        is_new_release: Boolean(book.is_new_release),
        is_premium: Boolean(book.is_premium),
        ebook_content: book.ebook_content || ''
      });
    }
    
    setShowBookDialog(true);
    setActiveStep(0);
  };

  const handleToggleFeatured = (bookId: string, isFeatured: boolean) => {
    updateBookStatusMutation.mutate({ id: bookId, statusData: { isFeatured } });
  };

  const handleToggleNewRelease = (bookId: string, isNewRelease: boolean) => {
    updateBookStatusMutation.mutate({ id: bookId, statusData: { isNewRelease } });
  };

  const handleTogglePremium = (bookId: string, isPremium: boolean) => {
    updateBookStatusMutation.mutate({ id: bookId, statusData: { isPremium } });
  };

  const handleDeleteBook = (bookId: string) => {
    if (window.confirm('Are you sure you want to delete this book? This action cannot be undone.')) {
      deleteBookMutation.mutate(bookId);
    }
  };

  const handleBulkAction = () => {
    if (bulkAction && selectedBooks.length > 0) {
      bulkUpdateBooksMutation.mutate({
        bookIds: selectedBooks,
        action: bulkAction,
      });
    }
  };

  const handleExportBooks = () => {
    // TODO: Implement export functionality
    alert('Export functionality will be implemented soon!');
  };

  const handleSaveBook = async () => {
    try {

      
      const formDataToSend = new FormData();
      
      // Add form fields with correct backend field names (matching database structure)
      const fieldMapping = {
        title: 'title',
        title_somali: 'title_somali',
        description: 'description',
        description_somali: 'description_somali',
        authors: 'authors',
        authors_somali: 'authors_somali',
        language: 'language',
        format: 'format',
        duration: 'duration',
        page_count: 'page_count',
        is_featured: 'is_featured',
        is_new_release: 'is_new_release',
        is_premium: 'is_premium',
        ebook_content: 'ebook_content'
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
      if (uploadedFiles.audio) {
        formDataToSend.append('audioFile', uploadedFiles.audio);
      }


      
      // Debug: Log exact data being sent to backend
      console.log('📤 EXACT DATA SENT TO BACKEND:');
      console.log('📋 FormData entries:');
      for (let [key, value] of formDataToSend.entries()) {
        console.log(`  ${key}:`, value);
      }
      console.log('📋 Selected categories:', formData.selectedCategories);
      console.log('📋 Book ID:', selectedBook?.id || 'NEW BOOK');
      
      if (selectedBook) {
        // Update existing book
        const result = await updateBookMutation.mutateAsync({ id: selectedBook.id, bookData: formDataToSend });
      } else {
        // Create new book
        const result = await createBookMutation.mutateAsync(formDataToSend);
      }
    } catch (error) {
      console.error('💥 Error saving book:', error);
      
      // Handle specific error cases
      if (error.response?.data?.code === 'INVALID_CATEGORIES') {
        alert(`Error: ${error.response.data.details}\n\nPlease select valid categories from the dropdown.`);
      } else if (error.response?.data?.error) {
        alert(`Error saving book: ${error.response.data.error}`);
      } else {
        alert(`Error saving book: ${error.message || 'Unknown error'}`);
      }
    }
  };

  const handleAddNewBook = () => {
    setSelectedBook(null);
    resetForm();
    setShowBookDialog(true);
  };

  if (error) {
    return (
      <Alert severity="error" sx={{ m: 2 }}>
        Failed to load books: {error.message}
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
        <Typography variant={isMobile ? "h5" : "h4"}>Book Management</Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={handleAddNewBook}
          size={isMobile ? "small" : "medium"}
        >
          {isMobile ? 'Add Book' : 'Add New Book'}
        </Button>
      </Box>

      {renderBookStats()}
      {renderFilters()}

      <Card sx={{ mt: 3 }}>
        <DataGrid
          key={dataGridKey}
          rows={booksData?.books || []}
          columns={columns}
          loading={isLoading}
          checkboxSelection
          onRowSelectionModelChange={(newSelection) => setSelectedBooks(newSelection as string[])}
          rowSelectionModel={selectedBooks}
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
      {renderBookDialog()}

      <Snackbar
        open={updateBookStatusMutation.isSuccess || bulkUpdateBooksMutation.isSuccess || 
              createBookMutation.isSuccess || updateBookMutation.isSuccess}
        autoHideDuration={6000}
        onClose={() => {}}
      >
        <Alert severity="success">
          {updateBookStatusMutation.isSuccess && 'Book status updated successfully!'}
          {bulkUpdateBooksMutation.isSuccess && 'Bulk operation completed successfully!'}
          {createBookMutation.isSuccess && 'Book created successfully!'}
          {updateBookMutation.isSuccess && 'Book updated successfully!'}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default BooksPage;
