# Remove Expert Functionality Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use compose:subagent (recommended) or compose:execute to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove all expert-related functionality from Moodiki, keeping only User and Admin roles.

**Architecture:** Delete all expert-specific files (views, models, services, tests), then surgically remove expert references from shared files (auth, navigation, chat, AI, admin). The chat system is tightly coupled to appointments and needs careful decoupling.

**Tech Stack:** Flutter/Dart, Supabase, Provider

## Global Constraints

- Keep only `UserRole.user` and `UserRole.admin` in the enum
- Remove all expert/appointment-related views, models, services
- Preserve all non-expert functionality (mood tracking, meditation, chat, AI chatbot, community posts)
- Run `flutter analyze` after each task group to catch compilation errors
- Run `flutter gen-l10n` after localization changes

---

## Task 1: Delete Expert-Only Files

**Covers:** Remove all files entirely dedicated to expert/appointment functionality.

**Files:**
- Delete: `lib/views/expert/expert_list_page.dart`
- Delete: `lib/views/expert/expert_detail_page.dart`
- Delete: `lib/views/expert/widgets/expert_card.dart`
- Delete: `lib/views/expert_dashboard/expert_main_page.dart`
- Delete: `lib/views/expert_dashboard/expert_dashboard_page.dart`
- Delete: `lib/views/expert_dashboard/appointments_page.dart`
- Delete: `lib/views/expert_dashboard/appointment_detail_page.dart`
- Delete: `lib/views/expert_dashboard/schedule_page.dart`
- Delete: `lib/views/expert_dashboard/analytics_page.dart`
- Delete: `lib/views/auth/expert_signup_page.dart`
- Delete: `lib/views/auth/expert_pending_approval_page.dart`
- Delete: `lib/views/appointment/booking_page.dart`
- Delete: `lib/views/appointment/mock_payment_page.dart`
- Delete: `lib/views/appointment/my_appointments_page.dart`
- Delete: `lib/views/appointment/widgets/call_type_selector.dart`
- Delete: `lib/views/appointment/widgets/duration_selector.dart`
- Delete: `lib/views/admin/admin_expert_management_page.dart`
- Delete: `lib/models/expert.dart`
- Delete: `lib/models/expert_user.dart`
- Delete: `lib/models/appointment.dart`
- Delete: `lib/models/availability.dart`
- Delete: `lib/services/expert_user_service.dart`
- Delete: `lib/services/appointment_service.dart`
- Delete: `lib/services/availability_service.dart`
- Delete: `test/models/expert_test.dart`
- Delete: `test/models/expert_user_and_availability_test.dart`

- [ ] **Step 1: Delete all expert-only files**

```bash
rm -f lib/views/expert/expert_list_page.dart lib/views/expert/expert_detail_page.dart lib/views/expert/widgets/expert_card.dart
rm -f lib/views/expert_dashboard/expert_main_page.dart lib/views/expert_dashboard/expert_dashboard_page.dart lib/views/expert_dashboard/appointments_page.dart lib/views/expert_dashboard/appointment_detail_page.dart lib/views/expert_dashboard/schedule_page.dart lib/views/expert_dashboard/analytics_page.dart
rm -f lib/views/auth/expert_signup_page.dart lib/views/auth/expert_pending_approval_page.dart
rm -f lib/views/appointment/booking_page.dart lib/views/appointment/mock_payment_page.dart lib/views/appointment/my_appointments_page.dart lib/views/appointment/widgets/call_type_selector.dart lib/views/appointment/widgets/duration_selector.dart
rm -f lib/views/admin/admin_expert_management_page.dart
rm -f lib/models/expert.dart lib/models/expert_user.dart lib/models/appointment.dart lib/models/availability.dart
rm -f lib/services/expert_user_service.dart lib/services/appointment_service.dart lib/services/availability_service.dart
rm -f test/models/expert_test.dart test/models/expert_user_and_availability_test.dart
```

- [ ] **Step 2: Remove empty directories**

```bash
rmdir lib/views/expert/widgets 2>/dev/null; rmdir lib/views/expert 2>/dev/null
rmdir lib/views/expert_dashboard 2>/dev/null
rmdir lib/views/appointment/widgets 2>/dev/null; rmdir lib/views/appointment 2>/dev/null
```

- [ ] **Step 3: Verify deletions**

```bash
ls lib/views/expert 2>&1 | grep -q "No such file" && echo "OK: expert deleted"
ls lib/views/expert_dashboard 2>&1 | grep -q "No such file" && echo "OK: expert_dashboard deleted"
ls lib/views/appointment 2>&1 | grep -q "No such file" && echo "OK: appointment deleted"
ls lib/models/expert.dart 2>&1 | grep -q "No such file" && echo "OK: expert model deleted"
ls lib/services/appointment_service.dart 2>&1 | grep -q "No such file" && echo "OK: appointment service deleted"
```

Expected: All OK messages

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "refactor: delete all expert-only files (views, models, services, tests)"
```

---

## Task 2: Update UserRole Enum and AppUser Model

**Covers:** Remove `UserRole.expert` from enum, update AppUser model.

**Files:**
- Modify: `lib/models/app_user.dart`

**Interfaces:**
- Consumes: none
- Produces: `UserRole` enum with only `user` and `admin`; `AppUser` class without `isExpert` getter

- [ ] **Step 1: Read current app_user.dart**

```bash
cat lib/models/app_user.dart
```

- [ ] **Step 2: Edit UserRole enum**

Remove `expert` from the enum. The enum should only have:
```dart
enum UserRole { user, admin }
```

Also remove the `isExpert` getter from AppUser class.

- [ ] **Step 3: Run analysis**

```bash
flutter analyze lib/models/app_user.dart
```

Expected: No errors in app_user.dart itself

- [ ] **Step 4: Commit**

```bash
git add lib/models/app_user.dart
git commit -m "refactor: remove UserRole.expert from enum"
```

---

## Task 3: Clean Up Auth Flows

**Covers:** Remove expert references from login, welcome, and signup pages.

**Files:**
- Modify: `lib/views/auth/login_page.dart`
- Modify: `lib/views/auth/welcome_page.dart`

**Interfaces:**
- Consumes: `UserRole` enum (now only `user` and `admin`)
- Produces: Auth pages without expert routing or signup options

- [ ] **Step 1: Edit login_page.dart**

Remove:
- Import of `expert_main_page.dart`
- All `else if (role == 'expert')` routing blocks

The login should only route to `HomePage` for users and `AdminMainPage` for admins.

- [ ] **Step 2: Edit welcome_page.dart**

Remove:
- Import of `expert_signup_page.dart`
- The "Join as Expert" `TextButton` block

- [ ] **Step 3: Run analysis**

```bash
flutter analyze lib/views/auth/login_page.dart lib/views/auth/welcome_page.dart
```

Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add lib/views/auth/login_page.dart lib/views/auth/welcome_page.dart
git commit -m "refactor: remove expert routing from auth pages"
```

---

## Task 4: Clean Up Home Page Navigation

**Covers:** Remove experts tab from bottom navigation.

**Files:**
- Modify: `lib/views/home/home_page.dart`
- Modify: `lib/views/home/new_home_page.dart`

**Interfaces:**
- Consumes: none
- Produces: Home page with 4 tabs (Home, Mood, News, Profile) instead of 5

- [ ] **Step 1: Edit home_page.dart**

Remove:
- Import of `expert_list_page.dart`
- `ExpertListPage()` from `_pages` array (the 4th tab at index 3)
- The 4th `_NavItem` with label `context.l10n.experts`

The bottom nav should have 4 items: Home, Mood, News, Profile.

- [ ] **Step 2: Edit new_home_page.dart**

Remove:
- Import of `expert_list_page.dart`
- The "Expert Consultation" `_QuickAction` entry

- [ ] **Step 3: Run analysis**

```bash
flutter analyze lib/views/home/home_page.dart lib/views/home/new_home_page.dart
```

Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add lib/views/home/home_page.dart lib/views/home/new_home_page.dart
git commit -m "refactor: remove experts tab from home navigation"
```

---

## Task 5: Clean Up Admin Dashboard

**Covers:** Remove expert management from admin pages.

**Files:**
- Modify: `lib/views/admin/admin_main_page.dart`
- Modify: `lib/views/admin/admin_dashboard_page.dart`
- Modify: `lib/views/admin/admin_user_management_page.dart`

**Interfaces:**
- Consumes: `UserRole` enum (now only `user` and `admin`)
- Produces: Admin pages without expert references

- [ ] **Step 1: Edit admin_main_page.dart**

Remove:
- Import of `admin_expert_management_page.dart`
- `case 2: currentTab = const AdminExpertManagementPage();`
- The 3rd `_buildNavItem` for "Experts"
- Renumber remaining nav items (if needed)

- [ ] **Step 2: Edit admin_dashboard_page.dart**

Remove:
- `_totalExperts`, `_pendingExpertApplications` state variables
- `experts` query from `_loadDashboardData()` and its processing
- "Experts" stat card
- "Expert Applications" action card

- [ ] **Step 3: Edit admin_user_management_page.dart**

Remove:
- `UserRole.expert` case from `_buildRoleBadge()` method
- `UserRole.expert` case from `_getRoleColor()` method

- [ ] **Step 4: Run analysis**

```bash
flutter analyze lib/views/admin/
```

Expected: No errors

- [ ] **Step 5: Commit**

```bash
git add lib/views/admin/
git commit -m "refactor: remove expert management from admin dashboard"
```

---

## Task 6: Clean Up Chat System

**Covers:** Remove appointment coupling from chat. The chat system is tightly coupled to appointments - need to decouple carefully.

**Files:**
- Modify: `lib/services/chat_service.dart`
- Modify: `lib/views/chat/chat_list_page.dart`
- Modify: `lib/views/chat/chat_detail_page.dart`

**Interfaces:**
- Consumes: `ChatRoom`, `ChatMessage` models
- Produces: Chat system that works without appointments (user-to-user or user-to-admin chat only)

- [ ] **Step 1: Edit chat_service.dart**

Remove:
- `syncAppointmentChatRoomsForUser()` method
- `expertId` param from `createOrGetChatRoom()` and `createChatRoom()` methods
- `canSendMessage()` method (takes `Appointment` and `isExpert`)
- `canJoinVideoCall()` method
- Import of `appointment.dart`

- [ ] **Step 2: Edit chat_list_page.dart**

Remove:
- Imports of `appointment_service.dart` and `appointment.dart`
- `AppointmentService` field and `_syncRoomsFromAppointments()` method
- Rewrite `_buildChatListItem` to not depend on appointments

- [ ] **Step 3: Edit chat_detail_page.dart**

Remove:
- Imports of `appointment.dart`, `appointment_service.dart`, `booking_page.dart`
- `expertName` and `expertId` constructor params
- `_appointment` field, `_loadAppointment()`, and all appointment-based logic
- `isExpert` checks throughout the UI
- `BookingPage` navigation

- [ ] **Step 4: Run analysis**

```bash
flutter analyze lib/services/chat_service.dart lib/views/chat/
```

Expected: No errors

- [ ] **Step 5: Commit**

```bash
git add lib/services/chat_service.dart lib/views/chat/
git commit -m "refactor: decouple chat system from appointments"
```

---

## Task 7: Clean Up AI Chatbot Tools

**Covers:** Remove expert-related tools from AI chatbot, keep only mood and report tools.

**Files:**
- Modify: `lib/ai/tools/tool_definitions.dart`
- Modify: `lib/ai/tools/tool_dispatcher.dart`
- Modify: `lib/services/ai_chatbot_service.dart`
- Modify: `lib/core/config/system_prompt.dart`

**Interfaces:**
- Consumes: Gemini API, Supabase service
- Produces: AI chatbot without expert booking tools

- [ ] **Step 1: Edit tool_definitions.dart**

Remove:
- `listExperts` declaration
- `checkExpertAvailability` declaration
- `bookSession` declaration

Keep only `generateMonthlyReport` (update description to remove appointment reference).

- [ ] **Step 2: Edit tool_dispatcher.dart**

Remove:
- `list_experts` handler
- `check_expert_availability` handler
- `book_session` handler

Keep only `generate_monthly_report` handler (update to not reference `Appointment` or `AppointmentStatus`).

- [ ] **Step 3: Edit ai_chatbot_service.dart**

Remove:
- Imports of `appointment_service.dart` and `availability_service.dart`
- Expert-related tool dispatcher initialization callbacks (`listExperts`, `getAvailability`, `getBookedTimeSlots`, `createAppointment`, `getUserAppointments`, `getExpertPrice`, `checkExistingAppointment`)

Keep only `getMoodEntries`, `generateTimeSlots`, and `generateMonthlyReport` functionality.

- [ ] **Step 4: Edit system_prompt.dart**

Remove:
- "expert booking" references from `_baseRules`
- Tool-calling instructions for `check_expert_availability` and `book_session`

- [ ] **Step 5: Run analysis**

```bash
flutter analyze lib/ai/ lib/services/ai_chatbot_service.dart lib/core/config/system_prompt.dart
```

Expected: No errors

- [ ] **Step 6: Commit**

```bash
git add lib/ai/ lib/services/ai_chatbot_service.dart lib/core/config/system_prompt.dart
git commit -m "refactor: remove expert tools from AI chatbot"
```

---

## Task 8: Clean Up Profile and Supabase Service

**Covers:** Remove expert references from profile page and supabase service.

**Files:**
- Modify: `lib/views/profile/profile_page.dart`
- Delete: `lib/views/profile/my_appointments_page.dart` (if it exists)
- Modify: `lib/services/supabase_service.dart`
- Modify: `lib/dummy_firebase.dart`

**Interfaces:**
- Consumes: Supabase client
- Produces: Services without expert/appointment methods

- [ ] **Step 1: Edit profile_page.dart**

Remove:
- Import of `my_appointments_page.dart`
- The "My Appointments" profile option

- [ ] **Step 2: Edit supabase_service.dart**

Remove:
- `getApprovedExperts()` method
- `getExpertById()` method
- `getUserAppointments()` method
- `getExpertAppointments()` method
- `updateAppointmentStatus()` method

- [ ] **Step 3: Edit dummy_firebase.dart**

Remove:
- `getExpertAppointments` mock method

- [ ] **Step 4: Run analysis**

```bash
flutter analyze lib/views/profile/profile_page.dart lib/services/supabase_service.dart lib/dummy_firebase.dart
```

Expected: No errors

- [ ] **Step 5: Commit**

```bash
git add lib/views/profile/ lib/services/supabase_service.dart lib/dummy_firebase.dart
git commit -m "refactor: remove expert references from profile and supabase service"
```

---

## Task 9: Update Localization Files

**Covers:** Remove all expert/appointment-related string keys from ARB files and regenerate.

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Regenerate: `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`, `lib/l10n/app_localizations_vi.dart`

**Interfaces:**
- Consumes: none
- Produces: Localization files without expert strings

- [ ] **Step 1: Remove keys from app_en.arb**

Remove these keys:
- `expert`, `experts`, `searchExperts`, `errorLoadingExperts`, `noExpertsFound`
- `bookAppointmentToGetStarted`, `expertConsultation`, `joinAsExpert`
- `couldNotLoadExpertInfo`, `expertNotAvailableOnDay`, `bookingConflictExpertNotAvailable`
- `bookingInvalidData`, `expertNotFound`, `expertIsNotAvailableOnSelectedDay`
- `anyNotesForExpert`, `myAppointments`, `myAppointmentsSubtitle`
- `bookAppointment`, `viewMyAppointments`, `availability`

- [ ] **Step 2: Remove same keys from app_vi.arb**

Remove the same keys as step 1.

- [ ] **Step 3: Regenerate localizations**

```bash
flutter gen-l10n
```

Expected: Successfully generated localizations

- [ ] **Step 4: Run full analysis**

```bash
flutter analyze
```

Expected: No errors

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/
git commit -m "refactor: remove expert-related localization strings"
```

---

## Task 10: Final Verification

**Covers:** Verify the entire codebase compiles and no expert references remain.

**Files:**
- Verify: all modified files

**Interfaces:**
- Consumes: all previous tasks
- Produces: Clean, compilable codebase without expert functionality

- [ ] **Step 1: Search for remaining expert references**

```bash
grep -r "expert" lib/ --include="*.dart" -l
grep -r "appointment" lib/ --include="*.dart" -l
grep -r "UserRole.expert" lib/ --include="*.dart"
```

Expected: No results (or only comments/documentation)

- [ ] **Step 2: Run full analysis**

```bash
flutter analyze
```

Expected: No errors

- [ ] **Step 3: Run tests**

```bash
flutter test
```

Expected: All tests pass

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "refactor: complete removal of expert functionality"
```

---

## Summary

| Task | Files Deleted | Files Modified |
|------|---------------|----------------|
| 1. Delete expert files | 27 | 0 |
| 2. Update UserRole enum | 0 | 1 |
| 3. Clean auth flows | 0 | 2 |
| 4. Clean home navigation | 0 | 2 |
| 5. Clean admin dashboard | 0 | 3 |
| 6. Clean chat system | 0 | 3 |
| 7. Clean AI tools | 0 | 4 |
| 8. Clean profile & service | 0 | 3 |
| 9. Update localization | 0 | 2 |
| 10. Final verification | 0 | 0 |
| **Total** | **27** | **20** |
