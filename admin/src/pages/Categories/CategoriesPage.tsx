import React, { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Box,
  Typography,
  Paper,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  IconButton,
  Tooltip,
  Alert,
  Chip,
} from '@mui/material'
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
} from '@mui/icons-material'
import { DataGrid, GridColDef, GridActionsCellItem } from '@mui/x-data-grid'
import { 
  getCategories, 
  createCategory, 
  updateCategory, 
  deleteCategory 
} from '@/services/adminAPI'
import { useDispatch } from 'react-redux'
import { addNotification } from '@/store/slices/uiSlice'

interface Category {
  id: string
  name: string
  name_somali: string
  description?: string
  book_count: number
  created_at: string
  updated_at: string
}

const CategoriesPage: React.FC = () => {
  const dispatch = useDispatch()
  const queryClient = useQueryClient()
  
  const [dialogOpen, setDialogOpen] = useState(false)
  const [editingCategory, setEditingCategory] = useState<Category | null>(null)
  const [formData, setFormData] = useState({
    name: '',
    name_somali: '',
    description: '',
  })

  // Fetch categories
  const { data: categories, isLoading } = useQuery({
    queryKey: ['admin-categories'],
    queryFn: () => getCategories(),
  })

  // Create/Update category mutation
  const categoryMutation = useMutation({
    mutationFn: (data: { name: string; name_somali: string; description?: string }) =>
      editingCategory
        ? updateCategory(editingCategory.id, data)
        : createCategory(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-categories'] })
      dispatch(addNotification({
        type: 'success',
        message: `Category ${editingCategory ? 'updated' : 'created'} successfully`,
      }))
      handleCloseDialog()
    },
    onError: (error: any) => {
      dispatch(addNotification({
        type: 'error',
        message: error.response?.data?.error || `Failed to ${editingCategory ? 'update' : 'create'} category`,
      }))
    },
  })

  // Delete category mutation
  const deleteCategoryMutation = useMutation({
    mutationFn: (id: string) => deleteCategory(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-categories'] })
      dispatch(addNotification({
        type: 'success',
        message: 'Category deleted successfully',
      }))
    },
    onError: (error: any) => {
      dispatch(addNotification({
        type: 'error',
        message: error.response?.data?.error || 'Failed to delete category',
      }))
    },
  })

  const handleOpenDialog = (category?: Category) => {
    if (category) {
      setEditingCategory(category)
      setFormData({
        name: category.name,
        name_somali: category.name_somali,
        description: category.description || '',
      })
    } else {
      setEditingCategory(null)
      setFormData({
        name: '',
        name_somali: '',
        description: '',
      })
    }
    setDialogOpen(true)
  }

  const handleCloseDialog = () => {
    setDialogOpen(false)
    setEditingCategory(null)
    setFormData({
      name: '',
      name_somali: '',
      description: '',
    })
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (formData.name && formData.name_somali) {
      categoryMutation.mutate(formData)
    }
  }

  const handleDelete = (id: string) => {
    const category = categories?.find(cat => cat.id === id)
    
    if (category && category.book_count > 0) {
      dispatch(addNotification({
        type: 'error',
        message: `Cannot delete category "${category.name}" because it is assigned to ${category.book_count} book(s). Please remove all books from this category first.`,
      }))
      return
    }
    
    if (window.confirm('Are you sure you want to delete this category?')) {
      deleteCategoryMutation.mutate(id)
    }
  }

  const columns: GridColDef[] = [
    {
      field: 'name',
      headerName: 'Name (English)',
      flex: 1,
      minWidth: 200,
    },
    {
      field: 'name_somali',
      headerName: 'Name (Somali)',
      flex: 1,
      minWidth: 200,
    },
    {
      field: 'description',
      headerName: 'Description',
      flex: 1,
      minWidth: 300,
      renderCell: (params) => (
        <Typography variant="body2" color="textSecondary">
          {params.value || 'No description'}
        </Typography>
      ),
    },
    {
      field: 'book_count',
      headerName: 'Books',
      width: 120,
      renderCell: (params) => (
        <Chip
          label={params.value || 0}
          size="small"
          color={params.value > 0 ? "primary" : "default"}
          variant={params.value > 0 ? "filled" : "outlined"}
          sx={{ 
            fontWeight: params.value > 0 ? 'bold' : 'normal',
            minWidth: '40px'
          }}
        />
      ),
    },
    {
      field: 'created_at',
      headerName: 'Created',
      width: 120,
      valueGetter: (params) => new Date(params.value).toLocaleDateString(),
    },
    {
      field: 'actions',
      headerName: 'Actions',
      width: 150,
      type: 'actions',
      getActions: (params) => [
        <GridActionsCellItem
          key="edit"
          icon={<EditIcon />}
          label="Edit"
          onClick={() => handleOpenDialog(params.row)}
        />,
        <GridActionsCellItem
          key="delete"
          icon={<DeleteIcon />}
          label={params.row.book_count > 0 ? "Cannot delete (has books)" : "Delete"}
          onClick={() => handleDelete(params.id as string)}
          disabled={params.row.book_count > 0}
          sx={{ 
            color: params.row.book_count > 0 ? 'text.disabled' : 'error.main',
            '&:hover': {
              backgroundColor: params.row.book_count > 0 ? 'transparent' : 'error.light'
            }
          }}
        />,
      ],
    },
  ]

  return (
    <Box>
      {/* Header */}
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4" fontWeight="bold">
          Category Management
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => handleOpenDialog()}
        >
          Add Category
        </Button>
      </Box>

      {/* Data Grid */}
      <Paper sx={{ height: 600, width: '100%' }}>
        <DataGrid
          rows={categories || []}
          columns={columns}
          loading={isLoading}
          getRowId={(row) => row.id}
          disableRowSelectionOnClick
          pageSizeOptions={[25, 50, 100]}
          initialState={{
            pagination: {
              paginationModel: { page: 0, pageSize: 25 },
            },
          }}
        />
      </Paper>

      {/* Add/Edit Dialog */}
      <Dialog open={dialogOpen} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
        <DialogTitle>
          {editingCategory ? 'Edit Category' : 'Add New Category'}
        </DialogTitle>
        <DialogContent>
          <Box component="form" onSubmit={handleSubmit} sx={{ mt: 2 }}>
            <TextField
              fullWidth
              label="Name (English)"
              value={formData.name}
              onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
              required
              sx={{ mb: 2 }}
            />
            <TextField
              fullWidth
              label="Name (Somali)"
              value={formData.name_somali}
              onChange={(e) => setFormData(prev => ({ ...prev, name_somali: e.target.value }))}
              required
              sx={{ mb: 2 }}
            />
            <TextField
              fullWidth
              label="Description"
              value={formData.description}
              onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
              multiline
              rows={3}
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>Cancel</Button>
          <Button
            onClick={handleSubmit}
            variant="contained"
            disabled={categoryMutation.isPending || !formData.name || !formData.name_somali}
          >
            {editingCategory ? 'Update' : 'Create'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  )
}

export default CategoriesPage
