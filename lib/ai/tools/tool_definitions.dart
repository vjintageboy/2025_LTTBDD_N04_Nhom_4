import 'package:google_generative_ai/google_generative_ai.dart';

class ToolDefinitions {
  static Tool get allTools => Tool(functionDeclarations: [
        generateMonthlyReport,
      ]);

  static final FunctionDeclaration generateMonthlyReport = FunctionDeclaration(
    'generate_monthly_report',
    'Thống kê mood của một tháng: số lần ghi nhận, điểm trung bình (thang 5), '
        'xu hướng (improving/stable/declining) và tối đa 3 yếu tố ảnh hưởng '
        'phổ biến nhất. Không có dữ liệu streak.',
    Schema(SchemaType.object, properties: {
      'month': Schema(SchemaType.integer, description: '1-12'),
      'year': Schema(SchemaType.integer, description: 'Năm 4 chữ số'),
    }, requiredProperties: [
      'month',
      'year'
    ]),
  );
}
