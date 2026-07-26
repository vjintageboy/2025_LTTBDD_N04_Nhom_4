// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Moodiki';

  @override
  String get appTagline => 'Track your emotions, elevate your mindset';

  @override
  String get appSubTagline => 'Your journey to mental wellness starts here';

  @override
  String get emotionalJourney => 'Emotional care journey';

  @override
  String get home => 'Home';

  @override
  String get meditation => 'Meditation';

  @override
  String get mood => 'Mood';

  @override
  String get news => 'News';

  @override
  String get community => 'Community';

  @override
  String get search => 'Search';

  @override
  String get notifications => 'Notifications';

  @override
  String get all => 'All';

  @override
  String get sortBy => 'Sort by:';

  @override
  String get latest => 'Latest';

  @override
  String get hottest => 'Hottest';

  @override
  String get mostLiked => 'Most Liked';

  @override
  String get mostDiscussed => 'Most Discussed';

  @override
  String get cannotLoadPosts => 'Cannot load posts';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get noPostsYet => 'No posts yet';

  @override
  String get beFirstToShare => 'Be the first to share!';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get errorPrefix => 'Error';

  @override
  String get deletePost => 'Delete Post';

  @override
  String get deletePostConfirm =>
      'Are you sure you want to delete this post? This action cannot be undone.';

  @override
  String get postDeletedSuccess => 'Post deleted successfully';

  @override
  String get errorDeletingPost => 'Error deleting post';

  @override
  String get errorLoadingPosts => 'Error loading posts';

  @override
  String get postDetail => 'Post';

  @override
  String get comments => 'Comments';

  @override
  String get errorLoadingComments => 'Error loading comments';

  @override
  String get noCommentsYet => 'No comments yet';

  @override
  String get beFirstToComment => 'Be the first to comment!';

  @override
  String get writeComment => 'Write a comment...';

  @override
  String get submit => 'Submit';

  @override
  String get anonymousComment => 'Comment anonymously';

  @override
  String get share => 'Share';

  @override
  String get likeFailed => 'Like failed';

  @override
  String get errorPostingComment => 'Error posting comment';

  @override
  String get cancel => 'Cancel';

  @override
  String get catMentalHealth => 'Mental Health';

  @override
  String get catMeditation => 'Meditation';

  @override
  String get catWellness => 'Wellness';

  @override
  String get catTips => 'Tips';

  @override
  String get catCommunity => 'Community';

  @override
  String get catNews => 'News';

  @override
  String get createPost => 'Create Post';

  @override
  String get editPost => 'Edit Post';

  @override
  String get postAction => 'Post';

  @override
  String get updateAction => 'Update';

  @override
  String get category => 'Category';

  @override
  String get required => 'Required';

  @override
  String get postAnonymously => 'Post Anonymously';

  @override
  String get identityHidden =>
      'Your identity will be hidden from the community.';

  @override
  String get postTitle => 'Post Title';

  @override
  String get titlePlaceholder => 'Give your post a clear title...';

  @override
  String get content => 'Content';

  @override
  String get contentPlaceholder =>
      'Share your thoughts, questions, or experiences with the collective...';

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get attachLink => 'Attach Link';

  @override
  String get guidelines => 'Guidelines';

  @override
  String get guidelinesText =>
      'Be respectful, stay relevant, and help our community thrive.';

  @override
  String get enterTitle => 'Please enter a title';

  @override
  String get enterContent => 'Please enter content';

  @override
  String get postUpdated => 'Post updated successfully';

  @override
  String get postCreated => 'Post created successfully';

  @override
  String get errorCreatingPost => 'Error creating post';

  @override
  String get profile => 'Profile';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get createAccount => 'Create Account';

  @override
  String get fullName => 'Full Name';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get or => 'OR';

  @override
  String get fullNameHint => 'John Doe';

  @override
  String get emailHint => 'your.email@company.com';

  @override
  String get passwordHint => '••••••••';

  @override
  String get signUpSubtitle => 'Join us and start your journey today';

  @override
  String get signInSubtitle => 'Welcome back! Please sign in to continue';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Please enter a valid email';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get passwordWeak =>
      'Password must be at least 8 characters with an uppercase letter, a lowercase letter, a number and a special character';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get nameTooShort => 'Name must be at least 2 characters';

  @override
  String get skip => 'Skip';

  @override
  String get quote1 =>
      '\"In the middle of a cold winter, I finally realized that within me lay an invincible summer.\"';

  @override
  String get quote1Author => 'ALBERT CAMUS';

  @override
  String get quote2 => '\"Feelings are just visitors. Let them come and go.\"';

  @override
  String get quote2Author => 'MOOJI';

  @override
  String get currentStreak => 'Current Streak';

  @override
  String get longestStreak => 'Longest Streak';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get editProfileSubtitle => 'Update your personal information';

  @override
  String get notificationsSubtitle => 'Manage notification preferences';

  @override
  String get statistics => 'Statistics';

  @override
  String get statisticsSubtitle => 'View your mood analytics';

  @override
  String get privacySecurity => 'Privacy & Security';

  @override
  String get privacySecuritySubtitle => 'Control your privacy settings';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get helpSupportSubtitle => 'Get help and contact us';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirmTitle => 'Logout';

  @override
  String get logoutConfirmMessage => 'Are you sure you want to logout?';

  @override
  String get howAreYouFeeling => 'How are you feeling today?';

  @override
  String get selectYourMood => 'Select your mood';

  @override
  String get addNote => 'Add a note (optional)';

  @override
  String get noteHint => 'What\'s on your mind?';

  @override
  String get saveMood => 'Save Mood';

  @override
  String get moodSaved => 'Mood saved successfully';

  @override
  String get moodAnalytics => 'Mood Analytics';

  @override
  String get veryPoor => 'Very Poor';

  @override
  String get poor => 'Poor';

  @override
  String get okay => 'Okay';

  @override
  String get good => 'Good';

  @override
  String get excellent => 'Excellent';

  @override
  String get trackMoodDescription => 'Tap on the emoji that matches your day';

  @override
  String get emotionFactorsHint =>
      'Pick what\'s influencing your feelings (optional)';

  @override
  String get moodNotePlaceholder => 'Add a note...';

  @override
  String get meditationLibrary => 'Meditation Library';

  @override
  String get findYourPeace => 'Find your peace';

  @override
  String get searchMeditations => 'Search meditations...';

  @override
  String get allCategories => 'All Categories';

  @override
  String get stress => 'Stress';

  @override
  String get stressRelief => 'Stress Relief';

  @override
  String get anxiety => 'Anxiety';

  @override
  String get sleep => 'Sleep';

  @override
  String get focus => 'Focus';

  @override
  String get beginner => 'Beginner';

  @override
  String get intermediate => 'Intermediate';

  @override
  String get advanced => 'Advanced';

  @override
  String get minutes => 'min';

  @override
  String get noMeditationsFound => 'No meditations found';

  @override
  String get tryAdjustingFilters => 'Try adjusting your filters';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get stop => 'Stop';

  @override
  String get yearsExperience => 'yrs exp';

  @override
  String get about => 'About';

  @override
  String get specializations => 'Specializations';

  @override
  String get selectDateTime => 'Select Date & Time';

  @override
  String get selectCallType => 'Select Call Type';

  @override
  String get videoCall => 'Video Call';

  @override
  String get voiceCall => 'Voice Call';

  @override
  String get inPerson => 'In Person';

  @override
  String get confirm => 'Confirm';

  @override
  String get payment => 'Payment';

  @override
  String get proceedToPayment => 'Proceed to Payment';

  @override
  String get admin => 'Admin';

  @override
  String get manageMeditations => 'Manage Meditations';

  @override
  String get manageUsers => 'Manage Users';

  @override
  String get addMeditation => 'Add Meditation';

  @override
  String get editMeditation => 'Edit Meditation';

  @override
  String get title => 'Title';

  @override
  String get description => 'Description';

  @override
  String get duration => 'Duration';

  @override
  String get level => 'Level';

  @override
  String get audioFile => 'Audio File';

  @override
  String get imageUrl => 'Image URL';

  @override
  String get save => 'Save';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get createMeditation => 'Create Meditation';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get close => 'Close';

  @override
  String get filter => 'Filter';

  @override
  String get sort => 'Sort';

  @override
  String get apply => 'Apply';

  @override
  String get reset => 'Reset';

  @override
  String get userNotLoggedIn => 'User not logged in';

  @override
  String daysStreak(int count) {
    return '$count days';
  }

  @override
  String errorLogout(String error) {
    return 'Logout error: $error';
  }

  @override
  String get chatbot => 'Chatbot';

  @override
  String get askMeAnything => 'Ask me anything...';

  @override
  String get sendMessage => 'Send';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get amount => 'Amount';

  @override
  String get callType => 'Call Type';

  @override
  String get yourAccountBanned => 'Your account has been banned.';

  @override
  String banReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get contactSupport => 'Please contact support.';

  @override
  String get day => 'day';

  @override
  String get days => 'days';

  @override
  String get settings => 'Settings';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String get featuredMeditations => 'Featured Meditations';

  @override
  String get viewAll => 'View All';

  @override
  String get errorLoadingMeditations => 'Error loading meditations';

  @override
  String get categories => 'Categories';

  @override
  String get calm => 'Calm';

  @override
  String get trackMood => 'Track Mood';

  @override
  String get streak => 'Streak';

  @override
  String get moodLog => 'Mood Log';

  @override
  String get howAreYouFeelingToday => 'How are you feeling\ntoday?';

  @override
  String get notes => 'Notes';

  @override
  String get notesHint => 'What\'s on your mind? (Optional)';

  @override
  String get emotionFactors => 'What\'s affecting your mood?';

  @override
  String get work => 'Work';

  @override
  String get family => 'Family';

  @override
  String get health => 'Health';

  @override
  String get relationships => 'Relationships';

  @override
  String get exercise => 'Exercise';

  @override
  String get social => 'Social';

  @override
  String get money => 'Money';

  @override
  String get weather => 'Weather';

  @override
  String get food => 'Food';

  @override
  String get moodLoggedSuccess => 'Mood logged successfully! 🎉';

  @override
  String errorSavingMood(String error) {
    return 'Error saving mood: $error';
  }

  @override
  String get moodHistory => 'Mood History';

  @override
  String get allMoods => 'All Moods';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get noMoodEntries => 'No mood entries yet';

  @override
  String get startTrackingMood =>
      'Start tracking your mood to see your history';

  @override
  String get errorLoadingMoods => 'Error loading moods';

  @override
  String get moodDetails => 'Mood Details';

  @override
  String get factors => 'Factors';

  @override
  String get noFactors => 'No factors recorded';

  @override
  String get deleteMoodConfirm => 'Delete this mood entry?';

  @override
  String get deleteMoodMessage => 'This action cannot be undone.';

  @override
  String get moodDeletedSuccess => 'Mood entry deleted';

  @override
  String get errorDeletingMood => 'Error deleting mood';

  @override
  String get grouped => 'Grouped';

  @override
  String get calendar => 'Calendar';

  @override
  String get avg => 'Avg';

  @override
  String get entry => 'entry';

  @override
  String get entries => 'entries';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get legend => 'Legend';

  @override
  String get moodEntry => 'Mood Entry';

  @override
  String get howWereYouFeeling => 'How were you feeling?';

  @override
  String get whatInfluencedMood => 'What influenced your mood?';

  @override
  String get moodUpdatedSuccess => 'Mood entry updated successfully! 🎉';

  @override
  String get errorUpdatingMood => 'Error updating mood';

  @override
  String get available => 'available';

  @override
  String get tryAnotherFilter => 'Try selecting a different specialization';

  @override
  String get depression => 'Depression';

  @override
  String get from => 'From';

  @override
  String get yrs => 'yrs';

  @override
  String get rating => 'Rating';

  @override
  String get experience => 'Experience';

  @override
  String get reviews => 'Reviews';

  @override
  String get notesOptional => 'Notes (Optional)';

  @override
  String get audioOnlyConsultation => 'Audio only consultation';

  @override
  String get faceToFaceConsultation => 'Face-to-face video consultation';

  @override
  String get recommended => 'Recommended';

  @override
  String get min => 'min';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get history => 'History';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get completed => 'Completed';

  @override
  String get ratingSort => '⭐ Rating';

  @override
  String get durationSort => '⏱️ Duration';

  @override
  String get nameSort => '🔤 Name';

  @override
  String get meditationsFound => 'meditations found';

  @override
  String get meditationFound => 'meditation found';

  @override
  String get tryDifferentSearch => 'Try a different search or filter';

  @override
  String get benefits => 'Benefits';

  @override
  String get instructions => 'Instructions';

  @override
  String get aiAssistant => 'AI Assistant';

  @override
  String get alwaysReadyToHelp => 'Always ready to help you';

  @override
  String get clearChatHistory => 'Clear chat history?';

  @override
  String get clearChatConfirmation =>
      'Are you sure you want to clear all chat history?';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get welcomeTagline => 'Professional wellbeing platform';

  @override
  String get aiPoweredInsights => 'AI-powered insights';

  @override
  String get trackProgress => 'Track progress over time';

  @override
  String get privateSecure => 'Private and secure';

  @override
  String get getStarted => 'Get Started';

  @override
  String get termsAgreement => 'By continuing, you agree to our ';

  @override
  String get termsPrivacy => 'Terms & Privacy';

  @override
  String get signInToModiki => 'Sign in to MOODIKI';

  @override
  String get signInToContinue => 'Sign in to continue your journey';

  @override
  String get joinUsToday => 'Join us and start your journey today';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get email => 'Email';

  @override
  String get adminSetup => 'Admin Setup';

  @override
  String get howAreYouFeelingShort => 'How are you feeling?';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get allMeditations => 'All Meditations';

  @override
  String get featuredMeditation => 'Featured Meditation';

  @override
  String get dailyInspiration => 'Daily Inspiration';

  @override
  String get wellnessQuote =>
      'Take care of your mind, and your mind will take care of you.';

  @override
  String get wellnessQuoteAttribution => 'Mental Wellness App';

  @override
  String get moodLoggedSuccessful => 'Mood logged successfully!';

  @override
  String get failedToLogMood => 'Failed to log mood. Please try again.';

  @override
  String get unableToLoadData => 'Unable to load data. Please try again.';

  @override
  String get yourWellnessStreak => 'Your Wellness Streak';

  @override
  String get currentDays => 'Current';

  @override
  String get longestDays => 'Longest';

  @override
  String get totalLogs => 'Total';

  @override
  String get logsUnit => 'logs';

  @override
  String get daysUnit => 'days';

  @override
  String get logMood => 'Log mood';

  @override
  String get streakHistoryTitle => 'Streak History';

  @override
  String totalActivities(int count) {
    return '$count total activities';
  }

  @override
  String get keepItUp => 'Keep it up! Come back tomorrow';

  @override
  String get startYourStreak => 'Start your streak today!';

  @override
  String get hasActivity => 'Activity';

  @override
  String get noActivity => 'No Activity';

  @override
  String get future => 'Future';

  @override
  String get streakTips => 'Tips to Maintain Streak';

  @override
  String get tipDailyMood => 'Log your mood daily to build consistency';

  @override
  String get tipMeditation => 'Complete meditation sessions regularly';

  @override
  String get tipDailyReminder =>
      'Set daily reminders to check in with yourself';

  @override
  String get tipStreakReset => 'Streak resets if you miss a day';

  @override
  String get moodTrackerTitle => 'Mood Tracker';

  @override
  String get howAreYouFeelingHero => 'Hey there, how are you feeling?';

  @override
  String get moodHeroSubtitle => 'Take a moment to listen to yourself.';

  @override
  String get moodVeryBad => 'Very Bad';

  @override
  String get moodBad => 'Bad';

  @override
  String get moodNeutral => 'Neutral';

  @override
  String get moodExcellent => 'Excellent';

  @override
  String get chooseManyLabel => 'Pick many';

  @override
  String get factorsWhatAffect => 'What\'s affecting you?';

  @override
  String get notesToday => 'Today\'s Notes';

  @override
  String get notesPlaceholder => 'Anything special about your day?...';

  @override
  String get dailyInspirationQuote =>
      'Each day is a new beginning. Take a deep breath and smile at the world.';

  @override
  String get quoteInspirationLabel => 'Inspiration for a new day';

  @override
  String get moodAnalyticsTitle => 'Mood Analytics';

  @override
  String get week => 'Week';

  @override
  String get month => 'Month';

  @override
  String get year => 'Year';

  @override
  String get averageMood => 'Average Mood';

  @override
  String get totalEntries => 'Total Entries';

  @override
  String get moodTrend => 'Mood Trend';

  @override
  String get moodDistribution => 'Mood Distribution';

  @override
  String get topInfluencingFactors => 'Top Influencing Factors';

  @override
  String get highlights => 'Highlights';

  @override
  String get bestDay => 'Best Day';

  @override
  String get needsAttention => 'Needs Attention';

  @override
  String get noDataThisPeriod => 'No data for this period';

  @override
  String get startLoggingMoodAnalytics =>
      'Start logging your mood to see analytics';

  @override
  String errorLoadingMoodData(String error) {
    return 'Error loading mood data: $error';
  }

  @override
  String get noDataToDisplay => 'No data to display';

  @override
  String get data => 'Data';

  @override
  String get flow => 'Flow';

  @override
  String get growth => 'Growth';

  @override
  String get keyInfluencers => 'Key Influencers';

  @override
  String get moodTrends => 'Mood Trends';

  @override
  String get distribution => 'Distribution';

  @override
  String get monthlyHighlights => 'Monthly Highlights';

  @override
  String get pleaseSelectDateAndTime => 'Please select date and time';

  @override
  String get pleaseLoginFirst => 'Please login first';

  @override
  String get at => 'at';

  @override
  String get searchPosts => 'Search posts...';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get notificationsEmptyHint =>
      'We\'ll let you know when someone interacts with your posts';

  @override
  String get markAllAsRead => 'Mark all as read';

  @override
  String get postUnavailable => 'This post is no longer available';

  @override
  String get deleteAllNotifications => 'Delete all notifications';

  @override
  String get deleteAllNotificationsConfirm =>
      'Every notification will be deleted and cannot be restored.';
}
