// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Moodiki';

  @override
  String get appTagline => 'Theo dõi cảm xúc, nâng tầm tâm trí';

  @override
  String get appSubTagline =>
      'Hành trình chăm sóc sức khỏe tinh thần bắt đầu từ đây';

  @override
  String get emotionalJourney => 'Hành trình chăm sóc cảm xúc';

  @override
  String get home => 'Trang chủ';

  @override
  String get meditation => 'Thiền định';

  @override
  String get mood => 'Tâm trạng';

  @override
  String get news => 'Tin tức';

  @override
  String get community => 'Cộng đồng';

  @override
  String get search => 'Tìm kiếm';

  @override
  String get notifications => 'Thông báo';

  @override
  String get all => 'Tất cả';

  @override
  String get sortBy => 'Sắp xếp:';

  @override
  String get latest => 'Mới nhất';

  @override
  String get hottest => 'Hot nhất';

  @override
  String get mostLiked => 'Nhiều like nhất';

  @override
  String get mostDiscussed => 'Nhiều bình luận nhất';

  @override
  String get cannotLoadPosts => 'Không thể tải bài viết';

  @override
  String get tryAgain => 'Thử lại';

  @override
  String get noPostsYet => 'Chưa có bài viết nào';

  @override
  String get beFirstToShare => 'Hãy là người đầu tiên chia sẻ!';

  @override
  String get edit => 'Chỉnh sửa';

  @override
  String get delete => 'Xóa';

  @override
  String get justNow => 'vừa xong';

  @override
  String minutesAgo(int minutes) {
    return '$minutes phút trước';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours giờ trước';
  }

  @override
  String daysAgo(int days) {
    return '$days ngày trước';
  }

  @override
  String get errorPrefix => 'Lỗi';

  @override
  String get deletePost => 'Xóa bài viết';

  @override
  String get deletePostConfirm =>
      'Bạn có chắc chắn muốn xóa bài viết này? Hành động này không thể hoàn tác.';

  @override
  String get postDeletedSuccess => 'Đã xóa bài viết thành công';

  @override
  String get errorDeletingPost => 'Lỗi khi xóa bài viết';

  @override
  String get errorLoadingPosts => 'Lỗi tải bài viết';

  @override
  String get postDetail => 'Bài viết';

  @override
  String get comments => 'Bình luận';

  @override
  String get errorLoadingComments => 'Lỗi tải bình luận';

  @override
  String get noCommentsYet => 'Chưa có bình luận nào';

  @override
  String get beFirstToComment => 'Hãy là người đầu tiên bình luận!';

  @override
  String get writeComment => 'Viết bình luận...';

  @override
  String get submit => 'Gửi';

  @override
  String get anonymousComment => 'Bình luận ẩn danh';

  @override
  String get share => 'Chia sẻ';

  @override
  String get likeFailed => 'Thả like thất bại';

  @override
  String get errorPostingComment => 'Lỗi khi gửi bình luận';

  @override
  String get cancel => 'Hủy';

  @override
  String get catMentalHealth => 'Sức khỏe';

  @override
  String get catMeditation => 'Thiền';

  @override
  String get catWellness => 'Wellness';

  @override
  String get catTips => 'Mẹo';

  @override
  String get catCommunity => 'Cộng đồng';

  @override
  String get catNews => 'Tin tức';

  @override
  String get createPost => 'Tạo bài viết';

  @override
  String get editPost => 'Chỉnh sửa bài viết';

  @override
  String get postAction => 'Đăng';

  @override
  String get updateAction => 'Cập nhật';

  @override
  String get category => 'Danh mục';

  @override
  String get required => 'Bắt buộc';

  @override
  String get postAnonymously => 'Đăng ẩn danh';

  @override
  String get identityHidden => 'Danh tính của bạn sẽ được ẩn khỏi cộng đồng.';

  @override
  String get postTitle => 'Tiêu đề';

  @override
  String get titlePlaceholder => 'Đặt tiêu đề rõ ràng cho bài viết...';

  @override
  String get content => 'Nội dung';

  @override
  String get contentPlaceholder =>
      'Chia sẻ suy nghĩ, câu hỏi hoặc trải nghiệm của bạn với cộng đồng...';

  @override
  String get addPhoto => 'Thêm ảnh';

  @override
  String get attachLink => 'Đính kèm liên kết';

  @override
  String get guidelines => 'Hướng dẫn';

  @override
  String get guidelinesText =>
      'Hãy tôn trọng, giữ đúng chủ đề và giúp cộng đồng phát triển.';

  @override
  String get enterTitle => 'Vui lòng nhập tiêu đề';

  @override
  String get enterContent => 'Vui lòng nhập nội dung';

  @override
  String get postUpdated => 'Đã cập nhật bài viết thành công';

  @override
  String get postCreated => 'Đã tạo bài viết thành công';

  @override
  String get errorCreatingPost => 'Lỗi khi tạo bài viết';

  @override
  String get profile => 'Hồ sơ';

  @override
  String get signIn => 'Đăng nhập';

  @override
  String get signUp => 'Đăng ký';

  @override
  String get createAccount => 'Tạo tài khoản';

  @override
  String get fullName => 'Họ và tên';

  @override
  String get emailAddress => 'Địa chỉ Email';

  @override
  String get password => 'Mật khẩu';

  @override
  String get confirmPassword => 'Xác nhận mật khẩu';

  @override
  String get alreadyHaveAccount => 'Đã có tài khoản? ';

  @override
  String get dontHaveAccount => 'Chưa có tài khoản? ';

  @override
  String get forgotPassword => 'Quên mật khẩu?';

  @override
  String get or => 'HOẶC';

  @override
  String get fullNameHint => 'Nguyễn Văn A';

  @override
  String get emailHint => 'email.cua.ban@company.com';

  @override
  String get passwordHint => '••••••••';

  @override
  String get signUpSubtitle =>
      'Tham gia cùng chúng tôi và bắt đầu hành trình ngày hôm nay';

  @override
  String get signInSubtitle =>
      'Chào mừng trở lại! Vui lòng đăng nhập để tiếp tục';

  @override
  String get emailRequired => 'Email là bắt buộc';

  @override
  String get emailInvalid => 'Vui lòng nhập email hợp lệ';

  @override
  String get passwordRequired => 'Mật khẩu là bắt buộc';

  @override
  String get passwordTooShort => 'Mật khẩu phải có ít nhất 6 ký tự';

  @override
  String get passwordWeak =>
      'Mật khẩu phải từ 8 ký tự trở lên, gồm chữ hoa, chữ thường, số và ký tự đặc biệt';

  @override
  String get passwordsDoNotMatch => 'Mật khẩu không khớp';

  @override
  String get nameRequired => 'Tên là bắt buộc';

  @override
  String get nameTooShort => 'Tên phải có ít nhất 2 ký tự';

  @override
  String get skip => 'Bỏ qua';

  @override
  String get quote1 =>
      '\"Giữa mùa đông giá lạnh, tôi nhận ra bên trong mình vẫn có một mùa hè bất khuất.\"';

  @override
  String get quote1Author => 'ALBERT CAMUS';

  @override
  String get quote2 =>
      '\"Cảm xúc chỉ là những vị khách. Hãy để chúng đến rồi đi.\"';

  @override
  String get quote2Author => 'MOOJI';

  @override
  String get currentStreak => 'Chuỗi hiện tại';

  @override
  String get longestStreak => 'Chuỗi dài nhất';

  @override
  String get editProfile => 'Chỉnh sửa hồ sơ';

  @override
  String get editProfileSubtitle => 'Cập nhật thông tin cá nhân của bạn';

  @override
  String get notificationsSubtitle => 'Quản lý tùy chọn thông báo';

  @override
  String get statistics => 'Thống kê';

  @override
  String get statisticsSubtitle => 'Xem phân tích tâm trạng của bạn';

  @override
  String get privacySecurity => 'Quyền riêng tư & Bảo mật';

  @override
  String get privacySecuritySubtitle => 'Kiểm soát cài đặt quyền riêng tư';

  @override
  String get helpSupport => 'Trợ giúp & Hỗ trợ';

  @override
  String get helpSupportSubtitle => 'Nhận trợ giúp và liên hệ với chúng tôi';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get logoutConfirmTitle => 'Đăng xuất';

  @override
  String get logoutConfirmMessage =>
      'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?';

  @override
  String get howAreYouFeeling => 'Hôm nay bạn cảm thấy thế nào?';

  @override
  String get selectYourMood => 'Chọn tâm trạng của bạn';

  @override
  String get addNote => 'Thêm ghi chú (tùy chọn)';

  @override
  String get noteHint => 'Bạn đang nghĩ gì?';

  @override
  String get saveMood => 'Lưu tâm trạng';

  @override
  String get moodSaved => 'Đã lưu tâm trạng thành công';

  @override
  String get moodAnalytics => 'Phân tích tâm trạng';

  @override
  String get veryPoor => 'Rất tệ';

  @override
  String get poor => 'Tệ';

  @override
  String get okay => 'Bình thường';

  @override
  String get good => 'Tốt';

  @override
  String get excellent => 'Xuất sắc';

  @override
  String get trackMoodDescription =>
      'Chạm vào biểu tượng cảm xúc phù hợp với ngày của bạn';

  @override
  String get emotionFactorsHint =>
      'Chọn những điều ảnh hưởng tới cảm xúc (tùy chọn)';

  @override
  String get moodNotePlaceholder => 'Thêm ghi chú...';

  @override
  String get meditationLibrary => 'Thư viện thiền định';

  @override
  String get findYourPeace => 'Tìm sự bình yên của bạn';

  @override
  String get searchMeditations => 'Tìm kiếm bài thiền...';

  @override
  String get allCategories => 'Tất cả danh mục';

  @override
  String get stress => 'Căng thẳng';

  @override
  String get stressRelief => 'Giảm căng thẳng';

  @override
  String get anxiety => 'Lo âu';

  @override
  String get sleep => 'Giấc ngủ';

  @override
  String get focus => 'Tập trung';

  @override
  String get beginner => 'Cơ bản';

  @override
  String get intermediate => 'Trung cấp';

  @override
  String get advanced => 'Nâng cao';

  @override
  String get minutes => 'phút';

  @override
  String get noMeditationsFound => 'Không tìm thấy bài thiền';

  @override
  String get tryAdjustingFilters => 'Thử điều chỉnh bộ lọc của bạn';

  @override
  String get play => 'Phát';

  @override
  String get pause => 'Tạm dừng';

  @override
  String get stop => 'Dừng';

  @override
  String get yearsExperience => 'năm kinh nghiệm';

  @override
  String get about => 'Giới thiệu';

  @override
  String get specializations => 'Chuyên môn';

  @override
  String get selectDateTime => 'Chọn ngày & giờ';

  @override
  String get selectCallType => 'Chọn loại cuộc gọi';

  @override
  String get videoCall => 'Gọi video';

  @override
  String get voiceCall => 'Gọi thoại';

  @override
  String get inPerson => 'Gặp trực tiếp';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get payment => 'Thanh toán';

  @override
  String get proceedToPayment => 'Tiến hành thanh toán';

  @override
  String get admin => 'Quản trị';

  @override
  String get manageMeditations => 'Quản lý thiền định';

  @override
  String get manageUsers => 'Quản lý người dùng';

  @override
  String get addMeditation => 'Thêm thiền định';

  @override
  String get editMeditation => 'Chỉnh sửa thiền định';

  @override
  String get title => 'Tiêu đề';

  @override
  String get description => 'Mô tả';

  @override
  String get duration => 'Thời lượng';

  @override
  String get level => 'Cấp độ';

  @override
  String get audioFile => 'File âm thanh';

  @override
  String get imageUrl => 'URL hình ảnh';

  @override
  String get save => 'Lưu';

  @override
  String get saveChanges => 'Lưu thay đổi';

  @override
  String get createMeditation => 'Tạo thiền định';

  @override
  String get loading => 'Đang tải...';

  @override
  String get error => 'Lỗi';

  @override
  String get success => 'Thành công';

  @override
  String get close => 'Đóng';

  @override
  String get filter => 'Lọc';

  @override
  String get sort => 'Sắp xếp';

  @override
  String get apply => 'Áp dụng';

  @override
  String get reset => 'Đặt lại';

  @override
  String get userNotLoggedIn => 'Người dùng chưa đăng nhập';

  @override
  String daysStreak(int count) {
    return '$count ngày';
  }

  @override
  String errorLogout(String error) {
    return 'Lỗi đăng xuất: $error';
  }

  @override
  String get chatbot => 'Trợ lý AI';

  @override
  String get askMeAnything => 'Hỏi tôi bất cứ điều gì...';

  @override
  String get sendMessage => 'Gửi';

  @override
  String get date => 'Ngày';

  @override
  String get time => 'Giờ';

  @override
  String get amount => 'Số tiền';

  @override
  String get callType => 'Loại cuộc gọi';

  @override
  String get yourAccountBanned => 'Tài khoản của bạn đã bị cấm.';

  @override
  String banReason(String reason) {
    return 'Lý do: $reason';
  }

  @override
  String get contactSupport => 'Vui lòng liên hệ hỗ trợ.';

  @override
  String get day => 'ngày';

  @override
  String get days => 'ngày';

  @override
  String get settings => 'Cài đặt';

  @override
  String get goodMorning => 'Chào buổi sáng';

  @override
  String get goodAfternoon => 'Chào buổi chiều';

  @override
  String get goodEvening => 'Chào buổi tối';

  @override
  String get featuredMeditations => 'Thiền nổi bật';

  @override
  String get viewAll => 'Xem tất cả';

  @override
  String get errorLoadingMeditations => 'Lỗi tải thiền';

  @override
  String get categories => 'Danh mục';

  @override
  String get calm => 'Bình tĩnh';

  @override
  String get trackMood => 'Ghi nhận tâm trạng';

  @override
  String get streak => 'Chuỗi';

  @override
  String get moodLog => 'Ghi nhật ký tâm trạng';

  @override
  String get howAreYouFeelingToday => 'Hôm nay bạn cảm thấy\nthế nào?';

  @override
  String get notes => 'Ghi chú';

  @override
  String get notesHint => 'Bạn đang nghĩ gì? (Tùy chọn)';

  @override
  String get emotionFactors => 'Điều gì ảnh hưởng đến tâm trạng bạn?';

  @override
  String get work => 'Công việc';

  @override
  String get family => 'Gia đình';

  @override
  String get health => 'Sức khỏe';

  @override
  String get relationships => 'Mối quan hệ';

  @override
  String get exercise => 'Tập thể dục';

  @override
  String get social => 'Xã hội';

  @override
  String get money => 'Tài chính';

  @override
  String get weather => 'Thời tiết';

  @override
  String get food => 'Ăn uống';

  @override
  String get moodLoggedSuccess => 'Đã ghi nhận tâm trạng! 🎉';

  @override
  String errorSavingMood(String error) {
    return 'Lỗi lưu tâm trạng: $error';
  }

  @override
  String get moodHistory => 'Lịch sử tâm trạng';

  @override
  String get allMoods => 'Tất cả';

  @override
  String get thisWeek => 'Tuần này';

  @override
  String get thisMonth => 'Tháng này';

  @override
  String get noMoodEntries => 'Chưa có ghi nhận nào';

  @override
  String get startTrackingMood => 'Bắt đầu ghi nhận tâm trạng để xem lịch sử';

  @override
  String get errorLoadingMoods => 'Lỗi tải tâm trạng';

  @override
  String get moodDetails => 'Chi tiết tâm trạng';

  @override
  String get factors => 'Yếu tố';

  @override
  String get noFactors => 'Không có yếu tố nào';

  @override
  String get deleteMoodConfirm => 'Xóa ghi nhận này?';

  @override
  String get deleteMoodMessage => 'Hành động này không thể hoàn tác.';

  @override
  String get moodDeletedSuccess => 'Đã xóa ghi nhận';

  @override
  String get errorDeletingMood => 'Lỗi khi xóa';

  @override
  String get grouped => 'Theo nhóm';

  @override
  String get calendar => 'Lịch';

  @override
  String get avg => 'TB';

  @override
  String get entry => 'mục';

  @override
  String get entries => 'mục';

  @override
  String get today => 'Hôm nay';

  @override
  String get yesterday => 'Hôm qua';

  @override
  String get legend => 'Chú giải';

  @override
  String get moodEntry => 'Nhật ký tâm trạng';

  @override
  String get howWereYouFeeling => 'Bạn cảm thấy thế nào?';

  @override
  String get whatInfluencedMood => 'Điều gì ảnh hưởng đến tâm trạng của bạn?';

  @override
  String get moodUpdatedSuccess => 'Đã cập nhật nhật ký tâm trạng! 🎉';

  @override
  String get errorUpdatingMood => 'Lỗi khi cập nhật';

  @override
  String get available => 'có sẵn';

  @override
  String get tryAnotherFilter => 'Thử chọn chuyên môn khác';

  @override
  String get depression => 'Trầm cảm';

  @override
  String get from => 'Từ';

  @override
  String get yrs => 'năm';

  @override
  String get rating => 'Đánh giá';

  @override
  String get experience => 'Kinh nghiệm';

  @override
  String get reviews => 'Lượt đánh giá';

  @override
  String get notesOptional => 'Ghi chú (Tùy chọn)';

  @override
  String get audioOnlyConsultation => 'Tư vấn qua âm thanh';

  @override
  String get faceToFaceConsultation => 'Tư vấn trực tiếp qua video';

  @override
  String get recommended => 'Đề xuất';

  @override
  String get min => 'phút';

  @override
  String get upcoming => 'Sắp tới';

  @override
  String get history => 'Lịch sử';

  @override
  String get confirmed => 'Đã xác nhận';

  @override
  String get cancelled => 'Đã hủy';

  @override
  String get completed => 'Hoàn thành';

  @override
  String get ratingSort => '⭐ Đánh giá';

  @override
  String get durationSort => '⏱️ Thời lượng';

  @override
  String get nameSort => '🔤 Tên';

  @override
  String get meditationsFound => 'bài thiền';

  @override
  String get meditationFound => 'bài thiền';

  @override
  String get tryDifferentSearch => 'Thử tìm kiếm hoặc lọc khác';

  @override
  String get benefits => 'Lợi ích';

  @override
  String get instructions => 'Hướng dẫn';

  @override
  String get aiAssistant => 'Trợ lý AI';

  @override
  String get alwaysReadyToHelp => 'Luôn sẵn sàng hỗ trợ bạn';

  @override
  String get clearChatHistory => 'Xóa lịch sử chat?';

  @override
  String get clearChatConfirmation =>
      'Bạn có chắc muốn xóa toàn bộ lịch sử trò chuyện không?';

  @override
  String get typeMessage => 'Nhập tin nhắn...';

  @override
  String get welcomeTagline =>
      'Nền tảng chăm sóc sức khỏe tinh thần chuyên nghiệp';

  @override
  String get aiPoweredInsights => 'Phân tích bằng AI';

  @override
  String get trackProgress => 'Theo dõi tiến trình theo thời gian';

  @override
  String get privateSecure => 'Riêng tư và bảo mật';

  @override
  String get getStarted => 'Bắt đầu';

  @override
  String get termsAgreement => 'Bằng việc tiếp tục, bạn đồng ý với ';

  @override
  String get termsPrivacy => 'Điều khoản & Quyền riêng tư';

  @override
  String get signInToModiki => 'Đăng nhập vào MOODIKI';

  @override
  String get signInToContinue => 'Đăng nhập để tiếp tục hành trình của bạn';

  @override
  String get joinUsToday =>
      'Tham gia với chúng tôi và bắt đầu hành trình ngay hôm nay';

  @override
  String get orContinueWith => 'Hoặc tiếp tục với';

  @override
  String get email => 'Email';

  @override
  String get adminSetup => 'Thiết lập Admin';

  @override
  String get howAreYouFeelingShort => 'Bạn cảm thấy thế nào?';

  @override
  String get quickActions => 'Thao tác nhanh';

  @override
  String get allMeditations => 'Tất cả bài thiền';

  @override
  String get featuredMeditation => 'Thiền nổi bật';

  @override
  String get dailyInspiration => 'Cảm hứng hàng ngày';

  @override
  String get wellnessQuote =>
      'Hãy chăm sóc tâm trí của bạn, và tâm trí sẽ chăm sóc bạn.';

  @override
  String get wellnessQuoteAttribution => 'Ứng dụng Sức khỏe Tinh thần';

  @override
  String get moodLoggedSuccessful => 'Đã ghi nhận tâm trạng thành công!';

  @override
  String get failedToLogMood =>
      'Không thể ghi nhận tâm trạng. Vui lòng thử lại.';

  @override
  String get unableToLoadData => 'Không thể tải dữ liệu. Vui lòng thử lại.';

  @override
  String get yourWellnessStreak => 'Chuỗi Sức khỏe Của Bạn';

  @override
  String get currentDays => 'Hiện tại';

  @override
  String get longestDays => 'Dài nhất';

  @override
  String get totalLogs => 'Tổng cộng';

  @override
  String get logsUnit => 'lần';

  @override
  String get daysUnit => 'ngày';

  @override
  String get logMood => 'Ghi lại';

  @override
  String get streakHistoryTitle => 'Lịch Sử Chuỗi';

  @override
  String totalActivities(int count) {
    return 'Tổng $count hoạt động';
  }

  @override
  String get keepItUp => 'Phát huy nhé! Quay lại vào ngày mai';

  @override
  String get startYourStreak => 'Bắt đầu chuỗi của bạn hôm nay!';

  @override
  String get hasActivity => 'Có hoạt động';

  @override
  String get noActivity => 'Không hoạt động';

  @override
  String get future => 'Tương lai';

  @override
  String get streakTips => 'Mẹo Duy Trì Chuỗi';

  @override
  String get tipDailyMood =>
      'Ghi nhận tâm trạng hàng ngày để xây dựng thói quen';

  @override
  String get tipMeditation => 'Hoàn thành các buổi thiền định thường xuyên';

  @override
  String get tipDailyReminder => 'Đặt nhắc nhở hàng ngày để tự kiểm tra';

  @override
  String get tipStreakReset => 'Chuỗi sẽ reset nếu bạn bỏ lỡ một ngày';

  @override
  String get moodTrackerTitle => 'Theo Dõi Tâm Trạng';

  @override
  String get howAreYouFeelingHero => 'Chào bạn, tâm trạng bạn thế nào?';

  @override
  String get moodHeroSubtitle =>
      'Hãy dành một phút để lắng nghe bản thân mình.';

  @override
  String get moodVeryBad => 'Rất tệ';

  @override
  String get moodBad => 'Tệ';

  @override
  String get moodNeutral => 'Ổn';

  @override
  String get moodExcellent => 'Tuyệt vời';

  @override
  String get chooseManyLabel => 'Chọn nhiều mục';

  @override
  String get factorsWhatAffect => 'Điều gì ảnh hưởng đến bạn?';

  @override
  String get notesToday => 'Ghi chú hôm nay';

  @override
  String get notesPlaceholder => 'Hôm nay của bạn có gì đặc biệt không?...';

  @override
  String get dailyInspirationQuote =>
      '\"Mỗi ngày là một khởi đầu mới. Hãy hít một hơi thật sâu và mỉm cười với thế giới.\"';

  @override
  String get quoteInspirationLabel => 'Cảm hứng cho ngày mới';

  @override
  String get moodAnalyticsTitle => 'Phân tích tâm trạng';

  @override
  String get week => 'Tuần';

  @override
  String get month => 'Tháng';

  @override
  String get year => 'Năm';

  @override
  String get averageMood => 'Tâm trạng trung bình';

  @override
  String get totalEntries => 'Tổng số ghi nhận';

  @override
  String get moodTrend => 'Xu hướng tâm trạng';

  @override
  String get moodDistribution => 'Phân bố tâm trạng';

  @override
  String get topInfluencingFactors => 'Các yếu tố ảnh hưởng hàng đầu';

  @override
  String get highlights => 'Nổi bật';

  @override
  String get bestDay => 'Ngày tốt nhất';

  @override
  String get needsAttention => 'Cần chú ý';

  @override
  String get noDataThisPeriod => 'Không có dữ liệu trong khoảng thời gian này';

  @override
  String get startLoggingMoodAnalytics =>
      'Bắt đầu ghi nhận tâm trạng để xem phân tích';

  @override
  String errorLoadingMoodData(String error) {
    return 'Lỗi tải dữ liệu tâm trạng: $error';
  }

  @override
  String get noDataToDisplay => 'Không có dữ liệu để hiển thị';

  @override
  String get data => 'Dữ liệu';

  @override
  String get flow => 'Dòng chảy';

  @override
  String get growth => 'Tăng trưởng';

  @override
  String get keyInfluencers => 'Yếu tố ảnh hưởng chính';

  @override
  String get aiInsight => 'Phân tích bằng AI';

  @override
  String get aiInsightPrompt =>
      'Để AI đọc dữ liệu tâm trạng của bạn trong khoảng này và chỉ ra điều đáng chú ý.';

  @override
  String get aiInsightAnalyze => 'Phân tích';

  @override
  String get aiInsightAnalyzing => 'Đang phân tích…';

  @override
  String get aiInsightRetry => 'Thử lại';

  @override
  String aiInsightError(String error) {
    return 'Chưa phân tích được. $error';
  }

  @override
  String get moodTrends => 'Xu hướng tâm trạng';

  @override
  String get distribution => 'Phân bố';

  @override
  String get monthlyHighlights => 'Nổi bật tháng này';

  @override
  String get pleaseSelectDateAndTime => 'Vui lòng chọn ngày và giờ';

  @override
  String get pleaseLoginFirst => 'Vui lòng đăng nhập trước';

  @override
  String get at => 'lúc';

  @override
  String get searchPosts => 'Tìm bài viết...';

  @override
  String get noNotificationsYet => 'Chưa có thông báo nào';

  @override
  String get notificationsEmptyHint =>
      'Chúng tôi sẽ báo cho bạn khi có người tương tác với bài viết của bạn';

  @override
  String get markAllAsRead => 'Đánh dấu tất cả đã đọc';

  @override
  String get postUnavailable => 'Bài viết không còn nữa';

  @override
  String get deleteAllNotifications => 'Xóa tất cả thông báo';

  @override
  String get deleteAllNotificationsConfirm =>
      'Toàn bộ thông báo sẽ bị xóa và không thể khôi phục.';
}
