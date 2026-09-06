-- Seed 25 ngày mood gần nhất cho user 123@gmail.com
-- Chạy trong Supabase SQL Editor, hoặc: npx prisma db execute --file seed_mood_123.sql --schema schema.prisma

insert into mood_entries (user_id, mood_score, note, emotion_factors, tags, created_at, updated_at)
select
  u.id,
  d.score,
  d.note,
  d.factors,
  '{}'::text[],
  ts.at,
  ts.at
from users u
cross join (values
  (24, 2, 'Deadline dồn dập, ngủ không đủ giấc.',            array['work','sleep']),
  (23, 3, 'Bình thường, không có gì đặc biệt.',              array['work']),
  (22, 2, 'Cãi nhau với người thân, thấy mệt.',              array['family','relationships']),
  (21, 3, 'Đi bộ buổi tối, dễ chịu hơn chút.',               array['exercise','weather']),
  (20, 3, 'Ngày làm việc ổn, ăn uống đầy đủ.',               array['work','food']),
  (19, 4, 'Gặp bạn cũ, cười nhiều.',                         array['social','relationships']),
  (18, 3, 'Hơi lo chuyện tiền bạc cuối tháng.',              array['money']),
  (17, 2, 'Cảm cúm, nằm cả ngày.',                           array['health','sleep']),
  (16, 3, 'Đỡ ốm, bắt đầu làm lại việc.',                    array['health','work']),
  (15, 4, 'Ngủ đủ 8 tiếng, tỉnh táo hẳn.',                   array['sleep','health']),
  (14, 4, 'Tập gym trở lại sau một tuần nghỉ.',              array['exercise','health']),
  (13, 3, 'Trời mưa cả ngày, hơi uể oải.',                   array['weather']),
  (12, 5, 'Xong project lớn, nhẹ cả người!',                 array['work']),
  (11, 4, 'Ăn tối với gia đình, ấm áp.',                     array['family','food']),
  (10, 3, 'Bận rộn nhưng kiểm soát được.',                   array['work']),
  ( 9, 4, 'Thiền 15 phút buổi sáng, tập trung tốt.',         array['health','sleep']),
  ( 8, 4, 'Nhận lương, lên kế hoạch tiết kiệm.',             array['money','work']),
  ( 7, 5, 'Cuối tuần đi chơi xa, rất vui.',                  array['social','weather']),
  ( 6, 3, 'Thứ hai uể oải, ngủ dậy muộn.',                   array['sleep','work']),
  ( 5, 4, 'Việc trôi chảy, đồng nghiệp hỗ trợ nhiệt tình.',  array['work','social']),
  ( 4, 5, 'Chạy bộ 5km, cảm giác tuyệt vời.',                array['exercise','health']),
  ( 3, 4, 'Nấu ăn ở nhà, tiết kiệm và ngon.',                array['food','money']),
  ( 2, 5, 'Được khen trong cuộc họp.',                       array['work','social']),
  ( 1, 4, 'Ngày yên bình, đọc sách buổi tối.',               array['sleep']),
  ( 0, 5, 'Thấy mình đang tiến bộ mỗi ngày.',                array['health','exercise'])
) as d(days_ago, score, note, factors)
cross join lateral (
  select ((current_date - d.days_ago)::timestamp
          + make_interval(hours => 20, mins => (d.days_ago * 7) % 60))
         at time zone 'Asia/Ho_Chi_Minh' as at
) ts
where u.email = '123@gmail.com';
