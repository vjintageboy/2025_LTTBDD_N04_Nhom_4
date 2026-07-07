import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:n04_app/ai/tools/tool_definitions.dart';

void main() {
  group('ToolDefinitions', () {
    test('allTools contains exactly 1 FunctionDeclaration', () {
      final tool = ToolDefinitions.allTools;
      expect(tool.functionDeclarations, isNotNull);
      expect(tool.functionDeclarations!.length, equals(1));
    });

    test('generateMonthlyReport name equals generate_monthly_report', () {
      expect(
        ToolDefinitions.generateMonthlyReport.name,
        equals('generate_monthly_report'),
      );
    });

    test('generateMonthlyReport required properties contains month and year',
        () {
      final required =
          ToolDefinitions.generateMonthlyReport.parameters!.requiredProperties;
      expect(required, isNotNull);
      expect(required, containsAll(['month', 'year']));
    });

    test('generateMonthlyReport description is not empty', () {
      expect(ToolDefinitions.generateMonthlyReport.description, isNotEmpty);
    });

    test('integer fields use SchemaType.integer', () {
      final reportProps =
          ToolDefinitions.generateMonthlyReport.parameters!.properties!;
      expect(reportProps['month']!.type, equals(SchemaType.integer));
      expect(reportProps['year']!.type, equals(SchemaType.integer));
    });

    test('allTools getter returns new Tool instance each call', () {
      final tool1 = ToolDefinitions.allTools;
      final tool2 = ToolDefinitions.allTools;
      expect(identical(tool1, tool2), isFalse);
      expect(
        tool1.functionDeclarations!.length,
        equals(tool2.functionDeclarations!.length),
      );
      expect(
        tool1.functionDeclarations![0].name,
        equals(tool2.functionDeclarations![0].name),
      );
    });
  });
}
