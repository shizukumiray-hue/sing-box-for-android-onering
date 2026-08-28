# Plan Implementasi Secret/Token untuk Remote Profile

## 1. Update TypedProfile.kt
- Tambah field `authToken: String = ""`
- Update serialization (Parcel read/write)
- Bump version jadi 2

## 2. Update HTTPClient.kt
- Tambah method `getString(url: String, authToken: String?): String`
- Set Authorization header jika token ada

## 3. Update UI Components
- EditProfileViewModel.kt - tambah authToken state
- EditProfileScreen.kt - tambah input field untuk token
- NewProfileViewModel.kt - tambah authToken state
- NewProfileScreen.kt - tambah input field untuk token

## 4. Update All Remote Fetch Locations
- UpdateProfileWork.kt - pass authToken
- EditProfileViewModel.kt - pass authToken saat update
- NewProfileViewModel.kt - pass authToken saat create
- DashboardViewModel.kt - pass authToken
- ProfilesCard.kt - pass authToken

## 5. Database Migration
- TypedProfile version 1 -> 2
- Auto-migrate dengan default empty string
