# Documentation

I'll explain the structure of this Swift project for an iOS news app called NewsFlowAI. This is a SwiftUI app that uses the MVVM (Model-View-ViewModel) architecture pattern.

## Project Overview

NewsFlowAI appears to be a news aggregation app that lets users:
- Browse and search for news articles
- Bookmark favorite articles
- Authenticate with user accounts (using Supabase)

## Architecture Breakdown

### 1. Entry Point

The entry point of the app is `NewsFlowAIApp.swift` (which seems to be called `NewsFlowApp.swift` in one of the files, a small naming inconsistency). This file contains the `@main` struct which is responsible for launching the app. It checks authentication status and shows either:
- `AuthView` if the user is not logged in
- `MainTabView` if the user is logged in

### 2. Models

Located in the `Models/` directory:
- `Article.swift`: Defines the structure for news articles with properties like title, summary, source, etc.
- `User.swift`: Defines the user structure with properties like id, email, display name.

### 3. ViewModels

Located in the `ViewModels/` directory:
- `AuthViewModel.swift`: Manages authentication state and provides sign-in, sign-up, and sign-out functionality
- `NewsViewModel.swift`: Manages fetching, displaying, and bookmarking news articles
- `BookmarkViewModel.swift`: Manages bookmarked articles

### 4. Views

Located in the `Views/` directory:

#### Authentication
- `Auth/AuthView.swift`: Login and registration screen

#### Main Structure
- `MainTabView.swift`: The tab-based main interface with tabs for Home, Search, Bookmarks, and Profile

#### News Views
- `News/HomeView.swift`: Displays news articles and selected keywords
- `News/SearchView.swift`: Allows searching for news articles
- `News/ArticleCardView.swift`: Card component for displaying article previews
- `News/ArticleDetailView.swift`: Detailed view of a single article

### 5. Services

Located in the `Services/` directory:
- `SupabaseClient.swift`: Singleton service that handles API communication with Supabase for authentication and data

## Data Flow

1. The app starts with `NewsFlowAIApp.swift` which instantiates `AuthViewModel`
2. Based on authentication status, it shows either `AuthView` or `MainTabView`
3. `MainTabView` initializes `NewsViewModel` and `BookmarkViewModel`
4. These ViewModels communicate with the `SupabaseClient` service to fetch and manipulate data
5. The Views display the data from the ViewModels and send user actions back to the ViewModels

## Dependency Map

```
NewsFlowAIApp.swift
├── AuthViewModel (handles auth state)
│   └── SupabaseClient (API communication)
├── AuthView (if not logged in)
└── MainTabView (if logged in)
    ├── NewsViewModel (news article management)
    │   └── SupabaseClient (API communication)
    ├── BookmarkViewModel (bookmark management)
    │   └── SupabaseClient (API communication)
    ├── HomeView (news feed)
    │   ├── ArticleCardView (article preview)
    │   └── ArticleDetailView (full article)
    ├── SearchView (search functionality)
    │   ├── ArticleCardView
    │   └── ArticleDetailView
    ├── BookmarksView (saved articles)
    └── ProfileView (user profile)
```

## Technical Details

### SwiftUI and SwiftData
- The app uses SwiftUI for the UI framework
- SwiftData appears to be used for local data storage

### Third-Party Dependencies
- Supabase: For authentication, database, and API functionality (imported packages include Auth, Functions, PostgREST, Realtime, Storage)

### Project Structure
The Xcode project structure has directories for:
- Models (data structures)
- Views (UI components)
- ViewModels (business logic)
- Services (API communication)
- Resources (assets)
- Utils (utility functions)

## Flow of Execution

1. `NewsFlowAIApp.swift` is the entry point that launches the app
2. It creates an `AuthViewModel` to manage authentication state
3. Based on `isAuthenticated` status, it shows either:
   - `AuthView` for login/registration
   - `MainTabView` for the main app interface
4. The `MainTabView` creates instances of `NewsViewModel` and `BookmarkViewModel`
5. These ViewModels handle communication with the `SupabaseClient` service
6. The Views observe changes to the ViewModels and update accordingly

In summary, this is a well-structured SwiftUI app using MVVM architecture with Supabase for backend services. The app focuses on displaying news articles with search and bookmarking capabilities, all with user authentication.
