# Syllabuddy

[![Made with Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B?style=flat&logo=flutter&logoColor=white)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)]()

**Syllabuddy** — a smart companion for college students.  
Syllabuddy collects and surfaces semester essentials — syllabi, subject lists, schedules, exams, hall allotments and bookmarks — so students can quickly stay organised and prepared.

> ⚡ A learning project built using **Flutter** (Dart). I built this to learn mobile architecture, UI patterns and Firebase integration while shipping a usable app.

---

## Demo GIF
<p align="center">
  <!-- demo GIF (full-size file displayed scaled down) -->
  <img src="https://github.com/user-attachments/assets/7776f718-520a-4ef5-9965-c4d6fe2baab3" width="480" alt="Syllabuddy demo GIF 1" />
  <img src="https://github.com/user-attachments/assets/0fd08839-dd70-4cde-b000-8942134e9f71" width="480" alt="Syllabuddy demo GIF 2" />
</p>

---

## What it does (short)
- Provide semester & course browsing (years, degrees, departments, semesters)  
- View syllabi and subject content quickly  
- Bookmarks for important subjects & syllabus items  
- Exams module + hall allotment view (user & admin flows)  
- Admin panel for content management (add/edit exams, subjects, semesters)  
- Multimode theming (Dark Mode + color modes)  
- Firebase-powered backend (auth, data, storage)

---

## Major Features (high level)
- ✅ Firebase Authentication (sign up, email verification, forgot password, auto-login)  
- ✅ User Profiles with edit capability  
- ✅ Dark mode + color mode system across app  
- ✅ Subject / syllabus browsing & search  
- ✅ Bookmarking & modern bookmark UI  
- ✅ Exams module and Hall Allotment view  
- ✅ Admin portal for content management  
- ✅ App icon + branding updates, and many UI/UX fixes

---

## Tech Stack
- **Flutter** (Dart) — mobile UI & app logic  
- **Firebase** — Authentication, Cloud Firestore (app data), Storage (optional)  
- Android & iOS build targets  
- (Optional) GitHub Actions for CI / APK build, Git LFS for large media

---

## Screenshots (optimized for size)
**Notes:** the original screenshots are large (1260×2800). To keep the README fast, the images below are displayed at **260px width** and link to the full-resolution files you uploaded.  
If you prefer the README to load even faster, create small thumbnails (`t-*.jpg`, ~300px wide) and replace the `src` values with those thumbnail URLs — I include instructions below.

### Screenshots gallery
<table>
  <tr>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/d007b522-b912-4741-8d8f-73f99470afc1">
        <img src="https://github.com/user-attachments/assets/d007b522-b912-4741-8d8f-73f99470afc1" width="260" alt="screenshot-01" />
      </a>
      <p>Landing</p>
    </td>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/e94d832f-911c-4d53-b8bf-00540a6c6904">
        <img src="https://github.com/user-attachments/assets/e94d832f-911c-4d53-b8bf-00540a6c6904" width="260" alt="screenshot-02" />
      </a>
      <p>Login / Auth</p>
    </td>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/9f880454-a363-40cb-b96c-295dacf4cfe1">
        <img src="https://github.com/user-attachments/assets/9f880454-a363-40cb-b96c-295dacf4cfe1" width="260" alt="screenshot-03" />
      </a>
      <p>Landing 2</p>
    </td>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/2992436c-4b71-481d-9124-9f7c74215088">
        <img src="https://github.com/user-attachments/assets/2992436c-4b71-481d-9124-9f7c74215088" width="260" alt="screenshot-04" />
      </a>
      <p>Subjects List</p>
    </td>
  </tr>

  <!-- (row 2) -->
  <tr>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/3ad1dd58-ca1b-4ca2-8eb2-89e4da001fc2">
        <img src="https://github.com/user-attachments/assets/3ad1dd58-ca1b-4ca2-8eb2-89e4da001fc2" width="260" alt="screenshot-05" />
      </a>
      <p>Subject Details</p>
    </td>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/b9b53f92-1e20-4980-88b8-c2e06445d7fb">
        <img src="https://github.com/user-attachments/assets/b9b53f92-1e20-4980-88b8-c2e06445d7fb" width="260" alt="screenshot-06" />
      </a>
      <p>Syllabus View</p>
    </td>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/e686044b-2ead-42c8-84fa-ec4bcd9399c3">
        <img src="https://github.com/user-attachments/assets/e686044b-2ead-42c8-84fa-ec4bcd9399c3" width="260" alt="screenshot-07" />
      </a>
      <p>Bookmarks</p>
    </td>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/03d5e59a-051c-484b-a942-89793707e4d9">
        <img src="https://github.com/user-attachments/assets/03d5e59a-051c-484b-a942-89793707e4d9" width="260" alt="screenshot-08" />
      </a>
      <p>Bookmarks (list)</p>
    </td>
  </tr>

  <!-- (row 3) -->
  <tr>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/06b7d0e1-a6ae-4fd3-81e6-f445afa2b2d7">
        <img src="https://github.com/user-attachments/assets/06b7d0e1-a6ae-4fd3-81e6-f445afa2b2d7" width="260" alt="screenshot-09" />
      </a>
      <p>Exams</p>
    </td>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/a616b58f-e1f8-4889-8034-0a2ee3d4e4f2">
        <img src="https://github.com/user-attachments/assets/a616b58f-e1f8-4889-8034-0a2ee3d4e4f2" width="260" alt="screenshot-10" />
      </a>
      <p>Hall Allotment</p>
    </td>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/d673dd72-685d-4a28-932d-0b03d39e3d55">
        <img src="https://github.com/user-attachments/assets/d673dd72-685d-4a28-932d-0b03d39e3d55" width="260" alt="screenshot-11" />
      </a>
      <p>Admin Dashboard</p>
    </td>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/87977d45-d941-42db-960c-e385d44bc2f3">
        <img src="https://github.com/user-attachments/assets/87977d45-d941-42db-960c-e385d44bc2f3" width="260" alt="screenshot-12" />
      </a>
      <p>Admin: Edit Screen</p>
    </td>
  </tr>

  <!-- (row 4) -->
  <tr>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/a815e4de-d075-47fd-b4b2-0b25022550a8">
        <img src="https://github.com/user-attachments/assets/a815e4de-d075-47fd-b4b2-0b25022550a8" width="260" alt="screenshot-13" />
      </a>
      <p>Profile</p>
    </td>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/45b75e6b-ab92-4039-bafd-7f634f3ae9e4">
        <img src="https://github.com/user-attachments/assets/45b75e6b-ab92-4039-bafd-7f634f3ae9e4" width="260" alt="screenshot-14" />
      </a>
      <p>Profile Edit</p>
    </td>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/f1249a0c-f5b6-4fc1-9d1a-842834cc58df">
        <img src="https://github.com/user-attachments/assets/f1249a0c-f5b6-4fc1-9d1a-842834cc58df" width="260" alt="screenshot-15" />
      </a>
      <p>Settings</p>
    </td>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/06c7d579-3a5b-4fb3-87ff-89d056812495">
        <img src="https://github.com/user-attachments/assets/06c7d579-3a5b-4fb3-87ff-89d056812495" width="260" alt="screenshot-16" />
      </a>
      <p>Theme Toggle</p>
    </td>
  </tr>

  <!-- (row 5) -->
  <tr>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/7620b409-603c-4672-8513-41b213439db1">
        <img src="https://github.com/user-attachments/assets/7620b409-603c-4672-8513-41b213439db1" width="260" alt="screenshot-17" />
      </a>
      <p>Search</p>
    </td>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/f8822482-9d3a-4dc6-aa1f-42b3283abf80">
        <img src="https://github.com/user-attachments/assets/f8822482-9d3a-4dc6-aa1f-42b3283abf80" width="260" alt="screenshot-18" />
      </a>
      <p>Subject Filters</p>
    </td>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/1db1a8c2-d516-4eab-9beb-de2e3f151590">
        <img src="https://github.com/user-attachments/assets/1db1a8c2-d516-4eab-9beb-de2e3f151590" width="260" alt="screenshot-19" />
      </a>
      <p>Semester View</p>
    </td>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/5ef97746-9a42-4315-8223-15ff7580cd6d">
        <img src="https://github.com/user-attachments/assets/5ef97746-9a42-4315-8223-15ff7580cd6d" width="260" alt="screenshot-20" />
      </a>
      <p>Degree & Dept</p>
    </td>
  </tr>

  <!-- (row 6) -->
  <tr>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/aaadd13c-42a4-47f3-baaf-8de6fa5e55c6">
        <img src="https://github.com/user-attachments/assets/aaadd13c-42a4-47f3-baaf-8de6fa5e55c6" width="260" alt="screenshot-21" />
      </a>
      <p>Dept / Course</p>
    </td>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/4ae3a85a-6d4a-4e5d-857a-0280abf8a56f">
        <img src="https://github.com/user-attachments/assets/4ae3a85a-6d4a-4e5d-857a-0280abf8a56f" width="260" alt="screenshot-22" />
      </a>
      <p>Course Detail</p>
    </td>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/186a4608-ed4c-4559-87f3-9b8bc760fcaf">
        <img src="https://github.com/user-attachments/assets/186a4608-ed4c-4559-87f3-9b8bc760fcaf" width="260" alt="screenshot-23" />
      </a>
      <p>Notifications</p>
    </td>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/24dfa82d-7311-4b0d-acec-2a624aedc529">
        <img src="https://github.com/user-attachments/assets/24dfa82d-7311-4b0d-acec-2a624aedc529" width="260" alt="screenshot-24" />
      </a>
      <p>Misc / Helpers</p>
    </td>
  </tr>

  <!-- (row 7) -->
  <tr>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/5fbf964d-7d61-4df0-8af1-65a7e549c787">
        <img src="https://github.com/user-attachments/assets/5fbf964d-7d61-4df0-8af1-65a7e549c787" width="260" alt="screenshot-25" />
      </a>
      <p>Overflow fixes</p>
    </td>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/2d25056f-30b9-4d4d-b00b-bfb0bc8d4a4a">
        <img src="https://github.com/user-attachments/assets/2d25056f-30b9-4d4d-b00b-bfb0bc8d4a4a" width="260" alt="screenshot-26" />
      </a>
      <p>UI polish</p>
    </td>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/32700fda-2757-4ed5-8b52-01baf57019c2">
        <img src="https://github.com/user-attachments/assets/32700fda-2757-4ed5-8b52-01baf57019c2" width="260" alt="screenshot-27" />
      </a>
      <p>Edge cases</p>
    </td>
    <td align="center">
      <a href="https://github.com/user-attachments/assets/e1dd3a2d-4bf3-468d-9583-267222a83b79">
        <img src="https://github.com/user-attachments/assets/e1dd3a2d-4bf3-468d-9583-267222a83b79" width="260" alt="screenshot-28" />
      </a>
      <p>Final screen</p>
    </td>
  </tr>

  <!-- GIF row (large preview across the width) -->
  <tr>
    <td align="center" colspan="4">
      <a href="https://github.com/user-attachments/assets/7776f718-520a-4ef5-9965-c4d6fe2baab3">
        <img src="https://github.com/user-attachments/assets/7776f718-520a-4ef5-9965-c4d6fe2baab3" width="720" alt="demo-gif" />
      </a>
      <p>Demo flow (GIF)</p>
    </td>
  </tr>
</table>

---

## Developer — Quick start

**Prerequisites**
- Flutter SDK (stable)
- Android SDK / Xcode (for platform builds)
- `flutter` on PATH

**Clone**
```bash
git clone https://github.com/<your-username>/syllabuddy.git
cd syllabuddy
flutter pub get
