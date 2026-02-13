# Implemented: User Follow System

## 1. Follow / Unfollow functionality

When visiting another user's profile, a **"Follow"** button now appears in the top-right corner.

- When clicked:
  - The button instantly changes to **"Following"** (visual feedback)
  - A new document is created in Firebase in both directions:
    - `users/{targetUserId}/followerList/{currentUserId}`
      - Document ID = current user's UID
      - Contains only one field: `followingDate` (timestamp)
    - `users/{currentUserId}/followingList/{targetUserId}`
      - Document ID = target user's UID
      - Contains only one field: `followingDate` (timestamp)

- When the button already says **"Following"** and is clicked again:
  - A confirmation dialog appears ("Unfollow this user?")
  - If confirmed:
    - Both documents are deleted:
      - `users/{targetUserId}/followerList/{currentUserId}`
      - `users/{currentUserId}/followingList/{targetUserId}`
    - Button reverts to **"Follow"**

## 2. Followers & Following lists + UI integration

- The total number of followers is now added to the "Community" counter shown on the main/home screen.

- In the Statistics screen:
  - The heart icon now displays the total number of followers.
  - Tapping the heart opens a new dedicated screen for follow lists.

**Follow lists screen behavior:**
- Top toggle bar with two options:
  - "X Followers" (shows people who follow you)
  - "X Following" (shows people you follow)
- Only one list is visible at a time.

**Each list item shows (left side):**
1. Profile picture
2. Display name
3. Username/handle

**Right-side actions (per list):**

- **Followers list** (people who follow you):
  - If you don't follow them back → shows **"Follow"** button
  - If you already follow them (mutual) → shows **"Message"** button (opens chat)
  - Next to the button: small **"×"** icon → unfollow (with confirmation dialog)

- **Following list** (people you follow):
  - Always shows **"Message"** button (opens chat)
  - Next to it: small **"×"** icon → unfollow (with confirmation dialog)

**Additional behaviors in both lists:**
- Tapping anywhere on the user row (except buttons) opens that user's profile (same as search result navigation).
- All unfollow actions (whether from the × icon or from the profile button) show a confirmation dialog before deleting the documents in both `followerList` and `followingList`.
