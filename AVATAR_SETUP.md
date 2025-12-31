# Avatar Upload Feature Setup

This document describes the avatar upload feature and how to set it up.

## Overview

The avatar upload feature allows users to:
- Upload a custom profile picture
- Crop and position the image for optimal display in avatar circles
- View avatars throughout the application
- See a default avatar for users who haven't uploaded one

## Setup Instructions

### 1. Run Database Migration

The avatar upload feature uses Rails Active Storage. Run the migration to create the necessary database tables:

```bash
bin/rails db:migrate
```

This will create the Active Storage tables (`active_storage_blobs`, `active_storage_attachments`, `active_storage_variant_records`).

### 2. Storage Configuration

The application is configured to use local disk storage in development. The uploaded files will be stored in the `storage/` directory.

For production, you may want to configure cloud storage (S3, Google Cloud Storage, or Azure). See `config/storage.yml` for configuration options.

### 3. Verify Installation

After running the migration, you can verify the feature by:

1. Starting the Rails server: `bin/rails server`
2. Logging in to your account
3. Navigating to your profile
4. Clicking "Edit"
5. Uploading and cropping an avatar image

## Features

### Avatar Upload & Cropping

- **Location**: Profile Edit page (`/profile/edit`)
- **Functionality**:
  - Click "Upload Image" button
  - Select an image file (any common image format)
  - Crop and position the image using the interactive cropper
  - Click "Apply" to save the cropped version

### Avatar Display

Avatars are displayed in the following locations:

1. **Sidebar**: Bottom left corner with user name
2. **Profile Page**: Large avatar with user details
3. **Dashboard**: Small avatars next to insight authors
4. **Insight Item Page**: Author avatar in the header
5. **Admin Users List**: Avatar next to each user's name

### Default Avatar

Users without a custom avatar will see:
- A default gray silhouette avatar image
- OR their initials in a colored circle (depending on the view)

## Technical Implementation

### Components

1. **Model**: `User` model with `has_one_attached :avatar`
2. **Controller**: `ProfilesController` handles avatar upload and removal
3. **Stimulus Controller**: `avatar_upload_controller.js` manages cropping UI
4. **Helper Methods**:
   - `user_avatar(user)` - displays avatar or default
   - `user_avatar_or_initials(user)` - displays avatar or initials
5. **Image Cropper**: Uses Cropper.js for client-side image cropping

### Files Modified

- `app/models/user.rb` - Added avatar attachment
- `app/controllers/profiles_controller.rb` - Handle avatar uploads
- `app/helpers/application_helper.rb` - Avatar display helpers
- `app/javascript/controllers/avatar_upload_controller.js` - Cropping logic
- `app/views/profiles/edit.html.erb` - Avatar upload UI
- Multiple view files - Avatar display integration

## Troubleshooting

### Migration Issues

If you encounter issues running the migration:

```bash
# Check migration status
bin/rails db:migrate:status

# Rollback if needed
bin/rails db:rollback

# Run migrations again
bin/rails db:migrate
```

### Missing Avatar Images

If avatars aren't displaying:

1. Check that Active Storage tables exist in the database
2. Verify the `storage/` directory has proper write permissions
3. Check Rails logs for any errors

### Cropper Not Working

If the image cropper doesn't appear:

1. Check browser console for JavaScript errors
2. Verify Cropper.js is loaded (check Network tab)
3. Clear browser cache and reload

## Dependencies

- **Rails Active Storage** (built into Rails 8)
- **Cropper.js 1.6.1** (loaded via CDN)
- **Stimulus** (for JavaScript controllers)
- **DaisyUI** (for UI components)
