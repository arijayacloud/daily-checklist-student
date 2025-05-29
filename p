# TK/Kindergarten Activity Checklist App - Flutter App

Create a **minimalist, informative, and modern** Flutter checklist application for kindergarten activities. Focus on checklist functionality where parents track children's activities at home and teachers monitor progress at school.

## **Design Philosophy**
- **Checklist-Focused:** Primary function is checking off completed activities
- **Dual Environment:** Activities done at home (parent) and school (teacher)  
- **Real-time Sync:** Progress visible to both parent and teacher instantly
- **Minimalist:** Clean checklist interface with essential tracking
- **Informative:** Clear progress indicators and completion status
- **Modern:** Contemporary checklist UI with smooth interactions

## **Core User Flow**
1. **Teacher** creates activities and assigns to children
2. **Parent** receives assigned activities as checklist items
3. **Parent** checks off activities completed at home
4. **Teacher** checks off activities completed at school
5. **Both** see real-time progress from both environments
6. **System** tracks completion from home vs school

## **Tech Stack**
- **Frontend:** Flutter (Material Design 3)
- **Backend:** Firebase (Firestore + Authentication)
- **State Management:** Provider
- **Profile Images:** DiceBear API
- **Focus:** Real-time checklist synchronization

## **Core Checklist Features**

### **1. Simple Authentication**
- Email/password login
- Two roles: Teacher & Parent
- Teacher creates parent accounts

### **2. Activity Management (Teacher)**
- Create activities with checklist format
- Set where activity can be done: "Home", "School", or "Both"
- Assign activities to specific children
- Set due dates for checklist completion
- **Create sequential steps for each activity**
- **Track progress of individual steps**

### **3. Checklist Assignment System**
- Teacher assigns activities as checklist items
- Auto-appear in parent's checklist view
- Clear activity descriptions and instructions
- Due date indicators

### **4. Parent Checklist Interface**
- **Primary Screen:** Clean checklist of assigned activities
- **Check/Uncheck:** Simple tap to mark completion
- **Status Icons:** Clear visual indicators (✓ Done, ⏱️ Pending, ⚠️ Overdue)
- **Filter Options:** Show All, Completed, Pending, Overdue
- **Progress Bar:** Visual completion percentage
- **Step Progress:** Track completion of individual steps within activities

### **5. Teacher Checklist Interface**
- **School Checklist:** Mark activities done at school
- **Home Progress Monitor:** See what parents have checked off
- **Dual Status View:** Activities completed at home vs school
- **Student Overview:** All children's checklist progress
- **Step Tracking:** Monitor individual step completion

### **6. Real-time Progress Sync**
- **Instant Updates:** Parent checks → Teacher sees immediately
- **Dual Completion:** Same activity can be checked by both parent and teacher
- **Environment Tracking:** Know where activity was completed
- **Progress Synchronization:** Real-time checklist status updates
- **Step Synchronization:** Real-time updates of individual step completion

### **7. Simple Observation Notes**
- **Quick Notes:** Add brief comments when checking off activities
- **Photo Option:** Attach one photo per checked activity (optional)
- **Time Tracking:** Auto-record when activity was checked off
- **Environment Tag:** "Completed at Home" or "Completed at School"

### **8. Plans and Reminders**
- **Daily Plans:** Schedule activities for specific days
- **Weekly Plans:** Create weekly routines and schedules
- **Reminders:** Set notification reminders for activities
- **Planning Interface:** Calendar view for planning activities
- **Recurring Plans:** Set activities to repeat on schedule

## **Database Structure (Checklist-Focused)**
```
Collections:
- users: {email, role, name, createdBy}
- children: {name, age, parentId, avatarUrl}
- activities: {title, description, environment, difficulty, hasSteps}
- activity_steps: {
    activityId,
    stepNumber,
    title,
    description,
    estimatedTimeMinutes
  }
- checklist_items: {
    childId, 
    activityId, 
    assignedDate, 
    dueDate,
    homeStatus: {completed, completedAt, notes, completedBy},
    schoolStatus: {completed, completedAt, notes, completedBy},
    overallStatus: 'pending'|'partial'|'complete'
  }
- step_progress: {
    checklistItemId,
    stepId,
    completed,
    completedAt,
    completedBy,
    environment
  }
- completion_logs: {checklistItemId, environment, completedBy, timestamp, notes}
- plans: {
    title,
    description,
    childId,
    createdBy,
    createdAt,
    planType: 'daily'|'weekly',
    startDate,
    endDate,
    recurrence: 'once'|'daily'|'weekly'|'monthly',
    recurrenceDays: [1,2,3,4,5,6,7], // days of week for weekly recurrence
    activities: [{activityId, time, duration}]
  }
- reminders: {
    planId,
    activityId,
    childId,
    time,
    notificationSent,
    notificationTime
  }
```

## **Key Screens (Checklist-Focused)**
1. **Login Screen** - Simple authentication
2. **Parent Checklist Dashboard** - Main checklist interface
3. **Teacher Assignment Screen** - Create and assign checklist items
4. **Teacher Progress Monitor** - Overview of all children's checklists
5. **Activity Detail Screen** - View completion status from both environments
6. **Child Progress Screen** - Individual child's checklist progress
7. **Activity Steps Screen** - View and complete individual activity steps
8. **Plans Calendar** - Daily/weekly planning interface
9. **Plan Detail Screen** - Create and edit plans

## **Checklist UI Components**
- **ChecklistItem Widget:** Activity title, status, due date, check button
- **ProgressIndicator Widget:** Visual completion percentage
- **StatusChip Widget:** Home/School completion indicators  
- **FilterBar Widget:** Quick filter for checklist states
- **CompletionBadge Widget:** Visual indicators for completion source
- **StepItem Widget:** Individual step with completion status
- **StepProgress Widget:** Visual indicator of steps completion
- **PlanCard Widget:** Display daily/weekly plan summary
- **ReminderChip Widget:** Display reminder status

## **Real-time Sync Implementation**
```dart
// Firestore listeners for real-time updates
Stream<List<ChecklistItem>> getChildChecklist(String childId) {
  return FirebaseFirestore.instance
    .collection('checklist_items')
    .where('childId', isEqualTo: childId)
    .snapshots()
    .map((snapshot) => snapshot.docs
        .map((doc) => ChecklistItem.fromFirestore(doc))
        .toList());
}

// Update checklist item completion
Future<void> markCompleted(String itemId, String environment) async {
  await FirebaseFirestore.instance
    .collection('checklist_items')
    .doc(itemId)
    .update({
      '${environment}Status.completed': true,
      '${environment}Status.completedAt': Timestamp.now(),
      '${environment}Status.completedBy': currentUserId,
    });
}

// Get activity steps
Stream<List<ActivityStep>> getActivitySteps(String activityId) {
  return FirebaseFirestore.instance
    .collection('activity_steps')
    .where('activityId', isEqualTo: activityId)
    .orderBy('stepNumber')
    .snapshots()
    .map((snapshot) => snapshot.docs
        .map((doc) => ActivityStep.fromFirestore(doc))
        .toList());
}

// Mark step as completed
Future<void> markStepCompleted(String stepId, String checklistItemId, String environment) async {
  await FirebaseFirestore.instance
    .collection('step_progress')
    .add({
      'stepId': stepId,
      'checklistItemId': checklistItemId,
      'completed': true,
      'completedAt': Timestamp.now(),
      'completedBy': currentUserId,
      'environment': environment
    });
}

// Get plans for child
Stream<List<Plan>> getChildPlans(String childId) {
  return FirebaseFirestore.instance
    .collection('plans')
    .where('childId', isEqualTo: childId)
    .snapshots()
    .map((snapshot) => snapshot.docs
        .map((doc) => Plan.fromFirestore(doc))
        .toList());
}
```

## **Checklist Functionality Priorities**
1. **Phase 1:** Basic checklist CRUD + Assignment
2. **Phase 2:** Real-time sync + Dual completion tracking  
3. **Phase 3:** Progress visualization + Simple notes
4. **Phase 4:** Activity steps + Step-by-step progress
5. **Phase 5:** Plans and reminders implementation
6. **Future:** Advanced analytics, streak tracking, rewards

## **Success Metrics (Checklist-Focused)**
- Parents can check off 10 activities in under 1 minute
- Teachers can assign checklist items to multiple children in under 2 minutes  
- Real-time sync updates appear within 2 seconds
- Checklist completion rate increases by 30%
- Zero missed checklist updates between parent and teacher
- App load time under 2 seconds for checklist view
- Step completion tracking provides 50% more granular insights
- Plans and reminders increase activity completion rates by 40%

## **Key Implementation Details**
- **Primary Focus:** Smooth, responsive checklist interface
- **Real-time Priority:** Instant synchronization between parent and teacher
- **Offline Support:** Cache checklist state, sync when online
- **Visual Feedback:** Clear completion animations and status changes
- **Environment Awareness:** Always track where activity was completed
- **Dual Completion:** Same activity can be checked by both parent and teacher
- **Step Progression:** Track individual steps within activities
- **Planning System:** Organize activities into daily and weekly plans

**Build this as a professional checklist application where the primary value is seamless activity tracking between home and school environments. The checklist interface should be the most polished and responsive part of the entire application.** 