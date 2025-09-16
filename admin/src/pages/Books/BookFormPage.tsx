import React, { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Box,
  Typography,
  Paper,
  TextField,
  Button,
  Grid,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  FormControlLabel,
  Switch,
  Chip,
  Alert,
  CircularProgress,
  Divider,
  IconButton,
  Tooltip,
} from '@mui/material'
import {
  Save as SaveIcon,
  Cancel as CancelIcon,
  CloudUpload as UploadIcon,
  Delete as DeleteIcon,
  Preview as PreviewIcon,
} from '@mui/icons-material'
import { useDropzone } from 'react-dropzone'
import { createBook, updateBook, getBook, getCategories } from '@/services/adminAPI'
import { useDispatch } from 'react-redux'
import { addNotification } from '@/store/slices/uiSlice'

interface BookFormData {
  title: string
  title_somali: string
  description: string
  description_somali: string
  authors: string
  narrator: string
  isbn: string
  publisher: string
  publication_year: string
  page_count: string
  duration_minutes: string
  language: string
  format: string
  genre: string
  age_group: string
  is_free: boolean
  price: string
  tags: string
  is_featured: boolean
  is_new_release: boolean
  is_popular: boolean
}

const BookFormPage: React.FC = () => {
  const navigate = useNavigate()
  const { id } = useParams<{ id: string }>()
  const dispatch = useDispatch()
  const queryClient = useQueryClient()
  const isEditing = Boolean(id)

  const [formData, setFormData] = useState<BookFormData>({
    title: '',
    title_somali: '',
    description: '',
    description_somali: '',
    authors: '',
    narrator: '',
    isbn: '',
    publisher: '',
    publication_year: '',
    page_count: '',
    duration_minutes: '',
    language: 'en',
    format: 'ebook',
    genre: '',
    age_group: '',
    is_free: true,
    price: '0',
    tags: '',
    is_featured: false,
    is_new_release: false,
    is_popular: false,
  })

  const [files, setFiles] = useState<{
    coverImage?: File
    ebookFile?: File
    audioFile?: File
    sampleText?: File
    sampleAudio?: File
  }>({})

  const [existingFiles, setExistingFiles] = useState<{
    coverImage?: string
    ebookFile?: string
    audioFile?: string
    sampleText?: string
    sampleAudio?: string
  }>({})

  // Fetch book data if editing
  const { data: bookData, isLoading: isLoadingBook } = useQuery({
    queryKey: ['admin-book', id],
    queryFn: () => getBook(id!),
    enabled: isEditing,
  })

  // Update form data when book data is loaded
  useEffect(() => {
    if (bookData && isEditing) {
      setFormData({
        title: bookData.title || '',
        title_somali: bookData.title_somali || '',
        description: bookData.description || '',
        description_somali: bookData.description_somali || '',
        authors: bookData.authors || '',
        narrator: bookData.narrator || '',
        isbn: bookData.isbn || '',
        publisher: bookData.publisher || '',
        publication_year: bookData.publication_year?.toString() || '',
        page_count: bookData.page_count?.toString() || '',
        duration_minutes: bookData.duration_minutes?.toString() || '',
        language: bookData.language || 'en',
        format: bookData.format || 'ebook',
        genre: bookData.genre || '',
        age_group: bookData.age_group || '',
        is_free: bookData.is_free || true,
        price: bookData.price?.toString() || '0',
        tags: Array.isArray(bookData.tags) ? bookData.tags.join(', ') : '',
        is_featured: bookData.is_featured || false,
        is_new_release: bookData.is_new_release || false,
        is_popular: bookData.is_popular || false,
      })

      setExistingFiles({
        coverImage: bookData.cover_image_url,
        ebookFile: bookData.ebook_file_url,
        audioFile: bookData.audio_file_url,
        sampleText: bookData.sample_text_url,
        sampleAudio: bookData.sample_audio_url,
      })
    }
  }, [bookData, isEditing])

  // Create/Update book mutation
  const bookMutation = useMutation({
    mutationFn: (data: FormData) =>
              isEditing ? updateBook(id!, data) : createBook(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-books'] })
      dispatch(addNotification({
        type: 'success',
        message: `Book ${isEditing ? 'updated' : 'created'} successfully`,
      }))
      navigate('/books')
    },
    onError: (error: any) => {
      dispatch(addNotification({
        type: 'error',
        message: error.response?.data?.error || `Failed to ${isEditing ? 'update' : 'create'} book`,
      }))
    },
  })

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value, type } = e.target
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? (e.target as HTMLInputElement).checked : value,
    }))
  }

  const handleSelectChange = (e: any) => {
    const { name, value } = e.target
    setFormData(prev => ({
      ...prev,
      [name]: value,
    }))
  }

  const handleSwitchChange = (name: string) => (event: React.ChangeEvent<HTMLInputElement>) => {
    setFormData(prev => ({
      ...prev,
      [name]: event.target.checked,
    }))
  }

  const handleFileDrop = (acceptedFiles: File[], fieldName: string) => {
    if (acceptedFiles.length > 0) {
      setFiles(prev => ({
        ...prev,
        [fieldName]: acceptedFiles[0],
      }))
    }
  }

  const removeFile = (fieldName: string) => {
    setFiles(prev => {
      const newFiles = { ...prev }
      delete newFiles[fieldName]
      return newFiles
    })
  }

  const removeExistingFile = (fieldName: string) => {
    setExistingFiles(prev => {
      const newFiles = { ...prev }
      delete newFiles[fieldName]
      return newFiles
    })
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    const formDataToSend = new FormData()
    
    // Add form fields
    Object.entries(formData).forEach(([key, value]) => {
      if (value !== undefined && value !== '') {
        formDataToSend.append(key, value.toString())
      }
    })

    // Add files
    Object.entries(files).forEach(([key, file]) => {
      if (file) {
        formDataToSend.append(key, file)
      }
    })

    // Add existing file URLs
    Object.entries(existingFiles).forEach(([key, url]) => {
      if (url) {
        formDataToSend.append(`${key}Url`, url)
      }
    })

    bookMutation.mutate(formDataToSend)
  }

  const FileUploadField: React.FC<{
    fieldName: string
    label: string
    accept: string
    existingFile?: string
  }> = ({ fieldName, label, accept, existingFile }) => {
    const { getRootProps, getInputProps, isDragActive } = useDropzone({
      accept: { [accept]: [] },
      onDrop: (files) => handleFileDrop(files, fieldName),
      multiple: false,
    })

    const hasFile = files[fieldName as keyof typeof files] || existingFile

    return (
      <Box>
        <Typography variant="subtitle2" gutterBottom>
          {label}
        </Typography>
        
        {existingFile && (
          <Box display="flex" alignItems="center" gap={1} mb={1}>
            <Chip label="Existing file" color="primary" size="small" />
            <IconButton
              size="small"
              onClick={() => removeExistingFile(fieldName)}
              color="error"
            >
              <DeleteIcon />
            </IconButton>
          </Box>
        )}

        {files[fieldName as keyof typeof files] && (
          <Box display="flex" alignItems="center" gap={1} mb={1}>
            <Chip
              label={files[fieldName as keyof typeof files]?.name}
              color="success"
              size="small"
            />
            <IconButton
              size="small"
              onClick={() => removeFile(fieldName)}
              color="error"
            >
              <DeleteIcon />
            </IconButton>
          </Box>
        )}

        {!hasFile && (
          <Box
            {...getRootProps()}
            sx={{
              border: '2px dashed',
              borderColor: isDragActive ? 'primary.main' : 'grey.300',
              borderRadius: 1,
              p: 2,
              textAlign: 'center',
              cursor: 'pointer',
              backgroundColor: isDragActive ? 'primary.light' : 'grey.50',
              '&:hover': {
                backgroundColor: 'grey.100',
              },
            }}
          >
            <input {...getInputProps()} />
            <UploadIcon sx={{ fontSize: 40, color: 'text.secondary', mb: 1 }} />
            <Typography variant="body2" color="textSecondary">
              {isDragActive ? 'Drop the file here' : 'Drag & drop a file here, or click to select'}
            </Typography>
          </Box>
        )}
      </Box>
    )
  }

  if (isLoadingBook) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    )
  }

  return (
    <Box>
      <Typography variant="h4" fontWeight="bold" mb={3}>
        {isEditing ? 'Edit Book' : 'Add New Book'}
      </Typography>

      <Paper sx={{ p: 3 }}>
        <Box component="form" onSubmit={handleSubmit}>
          {/* Basic Information */}
          <Typography variant="h6" gutterBottom>
            Basic Information
          </Typography>
          
          <Grid container spacing={3} mb={3}>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Title (English)"
                name="title"
                value={formData.title}
                onChange={handleInputChange}
                required
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Title (Somali)"
                name="title_somali"
                value={formData.titleSomali}
                onChange={handleInputChange}
                required
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Author"
                name="authors"
                value={formData.authors}
                onChange={handleInputChange}
                required
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Narrator"
                name="narrator"
                value={formData.narrator}
                onChange={handleInputChange}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Description (English)"
                name="description"
                value={formData.description}
                onChange={handleInputChange}
                multiline
                rows={3}
                required
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Description (Somali)"
                name="description_somali"
                value={formData.descriptionSomali}
                onChange={handleInputChange}
                multiline
                rows={3}
                required
              />
            </Grid>
          </Grid>

          <Divider sx={{ my: 3 }} />

          {/* Book Details */}
          <Typography variant="h6" gutterBottom>
            Book Details
          </Typography>
          
          <Grid container spacing={3} mb={3}>
            <Grid item xs={12} md={4}>
              <FormControl fullWidth required>
                <InputLabel>Language</InputLabel>
                <Select
                  name="language"
                  value={formData.language}
                  label="Language"
                  onChange={handleSelectChange}
                >
                  <MenuItem value="en">English</MenuItem>
                  <MenuItem value="so">Somali</MenuItem>
                  <MenuItem value="ar">Arabic</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} md={4}>
              <FormControl fullWidth required>
                <InputLabel>Format</InputLabel>
                <Select
                  name="format"
                  value={formData.format}
                  label="Format"
                  onChange={handleSelectChange}
                >
                  <MenuItem value="ebook">eBook</MenuItem>
                  <MenuItem value="audiobook">Audiobook</MenuItem>
                  <MenuItem value="both">Both</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                label="Genre"
                name="genre"
                value={formData.genre}
                onChange={handleInputChange}
                required
              />
            </Grid>
            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                label="Age Group"
                name="age_group"
                value={formData.age_group}
                onChange={handleInputChange}
              />
            </Grid>
            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                label="ISBN"
                name="isbn"
                value={formData.isbn}
                onChange={handleInputChange}
              />
            </Grid>
            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                label="Publisher"
                name="publisher"
                value={formData.publisher}
                onChange={handleInputChange}
              />
            </Grid>
            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                label="Publication Year"
                name="publication_year"
                value={formData.publication_year}
                onChange={handleInputChange}
                type="number"
              />
            </Grid>
            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                label="Page Count"
                name="page_count"
                value={formData.page_count}
                onChange={handleInputChange}
                type="number"
              />
            </Grid>
            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                label="Duration (minutes)"
                name="duration_minutes"
                value={formData.duration_minutes}
                onChange={handleInputChange}
                type="number"
              />
            </Grid>
          </Grid>

          <Divider sx={{ my: 3 }} />

          {/* Pricing and Features */}
          <Typography variant="h6" gutterBottom>
            Pricing and Features
          </Typography>
          
          <Grid container spacing={3} mb={3}>
            <Grid item xs={12} md={6}>
              <FormControlLabel
                control={
                  <Switch
                    checked={formData.is_free}
                    onChange={handleSwitchChange('is_free')}
                  />
                }
                label="Free Book"
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Price ($)"
                name="price"
                value={formData.price}
                onChange={handleInputChange}
                type="number"
                disabled={formData.isFree}
                inputProps={{ min: 0, step: 0.01 }}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Tags (comma-separated)"
                name="tags"
                value={formData.tags}
                onChange={handleInputChange}
                placeholder="fiction, adventure, young-adult"
              />
            </Grid>
            <Grid item xs={12} md={4}>
              <FormControlLabel
                control={
                  <Switch
                    checked={formData.is_featured}
                    onChange={handleSwitchChange('is_featured')}
                  />
                }
                label="Featured Book"
              />
            </Grid>
            <Grid item xs={12} md={4}>
              <FormControlLabel
                control={
                  <Switch
                    checked={formData.is_new_release}
                    onChange={handleSwitchChange('is_new_release')}
                  />
                }
                label="New Release"
              />
            </Grid>
            <Grid item xs={12} md={4}>
              <FormControlLabel
                control={
                  <Switch
                    checked={formData.is_popular}
                    onChange={handleSwitchChange('is_popular')}
                  />
                }
                label="Popular Book"
              />
            </Grid>
          </Grid>

          <Divider sx={{ my: 3 }} />

          {/* File Uploads */}
          <Typography variant="h6" gutterBottom>
            Files and Media
          </Typography>
          
          <Grid container spacing={3} mb={3}>
            <Grid item xs={12} md={6}>
              <FileUploadField
                fieldName="coverImage"
                label="Cover Image"
                accept="image/*"
                existingFile={existingFiles.coverImage}
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <FileUploadField
                fieldName="ebookFile"
                label="eBook File (PDF/EPUB)"
                accept=".pdf,.epub"
                existingFile={existingFiles.ebookFile}
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <FileUploadField
                fieldName="audioFile"
                label="Audio File (MP3)"
                accept="audio/*"
                existingFile={existingFiles.audioFile}
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <FileUploadField
                fieldName="sampleText"
                label="Sample Text"
                accept=".txt,.pdf"
                existingFile={existingFiles.sampleText}
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <FileUploadField
                fieldName="sampleAudio"
                label="Sample Audio"
                accept="audio/*"
                existingFile={existingFiles.sampleAudio}
              />
            </Grid>
          </Grid>

          {/* Action Buttons */}
          <Box display="flex" gap={2} justifyContent="flex-end">
            <Button
              variant="outlined"
              startIcon={<CancelIcon />}
              onClick={() => navigate('/books')}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              variant="contained"
              startIcon={<SaveIcon />}
              disabled={bookMutation.isPending}
            >
              {bookMutation.isPending ? (
                <CircularProgress size={20} />
              ) : (
                isEditing ? 'Update Book' : 'Create Book'
              )}
            </Button>
          </Box>
        </Box>
      </Paper>
    </Box>
  )
}

export default BookFormPage
