import 'package:google_generative_ai/google_generative_ai.dart';

class ToolDefinitions {
  static Tool get allTools => Tool(functionDeclarations: [
        generateMonthlyReport,
      ]);

  static final FunctionDeclaration generateMonthlyReport = FunctionDeclaration(
    'generate_monthly_report',
    'Sinh báo cáo tâm lý tháng: mood trends, streak',
    Schema(SchemaType.object, properties: {
      'month': Schema(SchemaType.integer, description: '1-12'),
      'year': Schema(SchemaType.integer, description: 'Năm 4 chữ số'),
    }, requiredProperties: [
      'month',
      'year'
    ]),
  );
}
