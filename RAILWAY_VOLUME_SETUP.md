# Railway Volume Setup for File Storage

## Overview
This guide explains how to set up persistent file storage for your Teekoob application on Railway, ensuring that uploaded PDFs, audio files, and images are preserved across deployments.

## Current File Upload Configuration

### Backend Configuration
- **Upload Directory**: `/app/uploads` (Railway persistent volume)
- **File Types Supported**:
  - **Documents**: PDF, EPUB, TXT
  - **Images**: JPEG, PNG, WebP, GIF
  - **Audio**: MP3, WAV, M4A, AAC, OGG, WebM, FLAC
- **File Size Limit**: 100MB per file
- **Max Files**: 5 files per request

### File Storage Paths
- **Cover Images**: `/uploads/coverImage-{timestamp}-{random}.{ext}`
- **Ebook Files**: `/uploads/ebookFile-{timestamp}-{random}.{ext}`
- **Audio Files**: `/uploads/audioFile-{timestamp}-{random}.{ext}`
- **Sample Text**: `/uploads/sampleText-{timestamp}-{random}.{ext}`
- **Sample Audio**: `/uploads/sampleAudio-{timestamp}-{random}.{ext}`

## Railway Volume Setup

### Step 1: Create Volume in Railway Dashboard
1. Go to your Railway project dashboard
2. Click on your backend service
3. Go to the "Volumes" tab
4. Click "Create Volume"
5. Configure:
   - **Name**: `uploads`
   - **Mount Path**: `/app/uploads`
   - **Size**: `1GB` (adjust based on needs)

### Step 2: Environment Variables
Railway will automatically set:
- `RAILWAY_VOLUME_MOUNT_PATH=/app/uploads`

### Step 3: Deploy Backend
The backend is already configured to use the Railway volume:
- Files are saved to `/app/uploads/`
- Static files are served from `/uploads/` endpoint
- Directory is created automatically if it doesn't exist

## File Access URLs

### Public URLs
Files uploaded through the admin panel will be accessible at:
```
https://teekoob-production.up.railway.app/uploads/{filename}
```

### Example URLs
- Cover Image: `https://teekoob-production.up.railway.app/uploads/coverImage-1703123456789-123456789.jpg`
- PDF File: `https://teekoob-production.up.railway.app/uploads/ebookFile-1703123456789-123456789.pdf`
- Audio File: `https://teekoob-production.up.railway.app/uploads/audioFile-1703123456789-123456789.mp3`

## Admin Panel File Upload

### Supported File Fields
1. **Cover Image** (`coverImage`): Book cover image
2. **Ebook File** (`ebookFile`): PDF or EPUB file
3. **Audio File** (`audioFile`): Audiobook audio file
4. **Sample Text** (`sampleText`): Sample text file
5. **Sample Audio** (`sampleAudio`): Sample audio file

### Upload Process
1. Admin selects files in the admin panel
2. Files are uploaded to Railway volume
3. File URLs are stored in database
4. Files are served via static file endpoint

## Database Storage

### Book Table Fields
- `cover_image_url`: `/uploads/coverImage-{timestamp}-{random}.{ext}`
- `ebook_url`: `/uploads/ebookFile-{timestamp}-{random}.{ext}`
- `audio_url`: `/uploads/audioFile-{timestamp}-{random}.{ext}`
- `sample_url`: `/uploads/sampleText-{timestamp}-{random}.{ext}`

## Troubleshooting

### File Not Found (404)
- Check if volume is properly mounted
- Verify file exists in `/app/uploads/` directory
- Check file permissions

### Upload Fails
- Verify file size is under 100MB
- Check file type is supported
- Ensure volume has sufficient space

### Volume Not Persisting
- Verify volume is created in Railway dashboard
- Check mount path is correct (`/app/uploads`)
- Ensure volume is attached to the service

## Monitoring

### Check Upload Directory
```bash
# SSH into Railway service (if available)
ls -la /app/uploads/
```

### Check Volume Status
- Go to Railway dashboard → Service → Volumes
- Verify volume is mounted and has space

## Best Practices

1. **File Naming**: Files are automatically renamed with timestamps to prevent conflicts
2. **File Types**: Only allow specific file types for security
3. **File Size**: Limit file sizes to prevent abuse
4. **Backup**: Consider backing up important files
5. **Cleanup**: Implement file cleanup for unused uploads

## Security Considerations

- File types are validated on upload
- File size limits prevent abuse
- Files are served through the backend (not direct access)
- Consider implementing file scanning for malware

## Scaling Considerations

- Volume size can be increased as needed
- Consider CDN for better performance
- Implement file compression for large files
- Monitor storage usage regularly
