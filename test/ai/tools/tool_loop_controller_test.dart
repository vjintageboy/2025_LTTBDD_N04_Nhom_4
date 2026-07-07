import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:n04_app/ai/tools/tool_dispatcher.dart';
import 'package:n04_app/ai/tools/tool_loop_controller.dart';

// ---------------------------------------------------------------------------
// SDK helpers
// ---------------------------------------------------------------------------

/// Builds a GenerateContentResponse that contains a single TextPart.
GenerateContentResponse _textResponse(String text) {
  return GenerateContentResponse(
    [
      Candidate(
        Content('model', [TextPart(text)]),
        null, // safetyRatings
        null, // citationMetadata
        FinishReason.stop,
        null, // finishMessage
      ),
    ],
    null, // promptFeedback
  );
}

/// Builds a GenerateContentResponse whose first candidate contains [calls].
GenerateContentResponse _functionCallResponse(
  List<({String name, Map<String, Object?> args})> calls,
) {
  return GenerateContentResponse([
    Candidate(
      Content('model', [for (final c in calls) FunctionCall(c.name, c.args)]),
      null,
      null,
      FinishReason.stop,
      null,
    ),
  ], null);
}

/// Builds a GenerateContentResponse with empty candidates list.
GenerateContentResponse _emptyCandidatesResponse() {
  return GenerateContentResponse([], null);
}

/// Builds a GenerateContentResponse with a candidate whose text part is empty.
GenerateContentResponse _emptyTextResponse() {
  return GenerateContentResponse([
    Candidate(
      Content('model', [TextPart('')]),
      null,
      null,
      FinishReason.stop,
      null,
    ),
  ], null);
}

// ---------------------------------------------------------------------------
// ToolDispatcher factory
// ---------------------------------------------------------------------------

const _userId = 'user-test';

/// Returns a ToolDispatcher wired with passthrough no-op defaults.
ToolDispatcher _makeDispatcher() {
  return ToolDispatcher(
    generateTimeSlots:
        ({
          required String startTime,
          required String endTime,
          required int intervalMinutes,
        }) => ['09:00'],
    getMoodEntries: (_, __, ___) async => [],
    userId: _userId,
  );
}

/// A ToolDispatcher whose dispatch() always returns [fixedResult].
class _FixedDispatcher extends ToolDispatcher {
  final Map<String, Object?> fixedResult;
  final List<({String name, Map<String, Object?> args})> calls = [];

  _FixedDispatcher({required this.fixedResult})
    : super(
        generateTimeSlots:
            ({
              required startTime,
              required endTime,
              required intervalMinutes,
            }) => [],
        getMoodEntries: (_, __, ___) async => [],
        userId: _userId,
      );

  @override
  Future<Map<String, Object?>> dispatch(
    String toolName,
    Map<String, Object?> args,
  ) async {
    calls.add((name: toolName, args: args));
    return fixedResult;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ToolLoopController', () {
    // -----------------------------------------------------------------------
    // 1. Happy path: FunctionCall first, then text → returns text
    // -----------------------------------------------------------------------
    test('happy path: dispatches function call then returns text', () async {
      final dispatcherSpy = _FixedDispatcher(fixedResult: {'status': 'ok'});
      final controller = ToolLoopController(dispatcher: dispatcherSpy);

      int callIndex = 0;
      final responses = [
        _functionCallResponse([
          (
            name: 'generate_monthly_report',
            args: {
              'month': 4,
              'year': 2024,
            },
          ),
        ]),
        _textResponse('Báo cáo đã sẵn sàng'),
      ];

      final result = await controller.execute(
        userMessage: 'Tạo báo cáo tháng 4',
        sendMessage: (content) async => responses[callIndex++],
      );

      expect(result, 'Báo cáo đã sẵn sàng');
      expect(dispatcherSpy.calls.length, 1);
      expect(dispatcherSpy.calls.first.name, 'generate_monthly_report');
    });

    // -----------------------------------------------------------------------
    // 2. Multi-tool: 2 FunctionCalls in one turn → both dispatched
    // -----------------------------------------------------------------------
    test('multi-tool: dispatches all FunctionCalls in a single turn', () async {
      final dispatcherSpy = _FixedDispatcher(fixedResult: {'ok': true});
      final controller = ToolLoopController(dispatcher: dispatcherSpy);

      int callIndex = 0;
      final responses = [
        _functionCallResponse([
          (
            name: 'generate_monthly_report',
            args: {
              'month': 3,
              'year': 2024,
            },
          ),
          (
            name: 'generate_monthly_report',
            args: {
              'month': 4,
              'year': 2024,
            },
          ),
        ]),
        _textResponse('Done'),
      ];

      final result = await controller.execute(
        userMessage: 'check two months',
        sendMessage: (content) async => responses[callIndex++],
      );

      expect(result, 'Done');
      expect(dispatcherSpy.calls.length, 2);
    });

    // -----------------------------------------------------------------------
    // 3. Direct text: sendMessage returns text immediately
    // -----------------------------------------------------------------------
    test(
      'direct text: returns text without dispatch when no FunctionCall',
      () async {
        final dispatcherSpy = _FixedDispatcher(fixedResult: {});
        final controller = ToolLoopController(dispatcher: dispatcherSpy);

        final result = await controller.execute(
          userMessage: 'Xin chào',
          sendMessage: (_) async => _textResponse('Xin chào lại!'),
        );

        expect(result, 'Xin chào lại!');
        expect(dispatcherSpy.calls, isEmpty);
      },
    );

    // -----------------------------------------------------------------------
    // 4. Max iterations: 5 FunctionCall responses → summarize prompt sent
    // -----------------------------------------------------------------------
    test(
      'max iterations: sends summarize prompt after 5 tool-call turns',
      () async {
        final dispatcherSpy = _FixedDispatcher(fixedResult: {'ok': true});
        final controller = ToolLoopController(dispatcher: dispatcherSpy);

        final capturedContents = <Content>[];
        int callIndex = 0;

        // First 5 calls return a FunctionCall; 6th call (summarize) returns text.
        GenerateContentResponse buildResponse(Content content) {
          capturedContents.add(content);
          if (callIndex < 5) {
            callIndex++;
            return _functionCallResponse([
              (
                name: 'generate_monthly_report',
                args: {
                  'month': callIndex,
                  'year': 2024,
                },
              ),
            ]);
          }
          callIndex++;
          return _textResponse('Tóm tắt: đã hoàn thành.');
        }

        final result = await controller.execute(
          userMessage: 'loop',
          sendMessage: (c) async => buildResponse(c),
        );

        expect(result, 'Tóm tắt: đã hoàn thành.');
        // 5 tool iterations + 1 summarize = 6 total sendMessage calls.
        expect(callIndex, 6);
        // The 6th content sent must contain the summarize prompt text.
        final lastContent = capturedContents.last;
        expect(lastContent.parts.first, isA<TextPart>());
        expect((lastContent.parts.first as TextPart).text, contains('tóm tắt'));
      },
    );

    // -----------------------------------------------------------------------
    // 5. Timeout: sendMessage hangs > 30s → TimeoutException propagates
    // -----------------------------------------------------------------------
    test(
      'timeout: TimeoutException propagates when sendMessage stalls',
      () async {
        final controller = ToolLoopController(dispatcher: _makeDispatcher());

        await expectLater(
          controller.execute(
            userMessage: 'freeze',
            // Returns a future that never completes → triggers .timeout()
            sendMessage: (_) => Completer<GenerateContentResponse>().future,
          ),
          throwsA(isA<TimeoutException>()),
        );
      },
      timeout: const Timeout(Duration(seconds: 35)),
    );

    // -----------------------------------------------------------------------
    // 6. Empty text response: null/empty text → returns empty string
    // -----------------------------------------------------------------------
    test(
      'empty text response: returns empty string without throwing',
      () async {
        final controller = ToolLoopController(dispatcher: _makeDispatcher());

        final result = await controller.execute(
          userMessage: 'hello',
          sendMessage: (_) async => _emptyTextResponse(),
        );

        expect(result, '');
      },
    );

    // -----------------------------------------------------------------------
    // 7. Empty candidates: response.candidates is empty → returns '' safely
    // -----------------------------------------------------------------------
    test('empty candidates: returns empty string safely', () async {
      final controller = ToolLoopController(dispatcher: _makeDispatcher());

      final result = await controller.execute(
        userMessage: 'empty',
        sendMessage: (_) async => _emptyCandidatesResponse(),
      );

      expect(result, '');
    });

    // -----------------------------------------------------------------------
    // 8. Dispatcher called with correct toolName and args
    // -----------------------------------------------------------------------
    test('dispatcher receives exact toolName and args', () async {
      final dispatcherSpy = _FixedDispatcher(fixedResult: {'slots': []});
      final controller = ToolLoopController(dispatcher: dispatcherSpy);

      final expectedArgs = {
        'month': 6,
        'year': 2024,
      };

      int callIndex = 0;
      await controller.execute(
        userMessage: 'generate report',
        sendMessage: (c) async {
          if (callIndex == 0) {
            callIndex++;
            return _functionCallResponse([
              (name: 'generate_monthly_report', args: expectedArgs),
            ]);
          }
          return _textResponse('Done');
        },
      );

      expect(dispatcherSpy.calls.length, 1);
      expect(dispatcherSpy.calls.first.name, 'generate_monthly_report');
      expect(dispatcherSpy.calls.first.args, expectedArgs);
    });

    // -----------------------------------------------------------------------
    // 9. Multiple concurrent tool calls are all resolved (Future.wait)
    // -----------------------------------------------------------------------
    test(
      'concurrent tool calls: all resolved before next sendMessage',
      () async {
        int completedCount = 0;

        // Override dispatch via a custom dispatcher that resolves futures.
        final trackingDispatcher = _TrackingDispatcher(
          onDispatch: (name, args) async {
            completedCount++;
            return {'result': completedCount};
          },
        );

        final controller = ToolLoopController(dispatcher: trackingDispatcher);

        int sendIndex = 0;
        await controller.execute(
          userMessage: 'two tools',
          sendMessage: (c) async {
            if (sendIndex == 0) {
              sendIndex++;
              return _functionCallResponse([
                (
                  name: 'generate_monthly_report',
                  args: {
                    'month': 1,
                    'year': 2024,
                  },
                ),
                (
                  name: 'generate_monthly_report',
                  args: {
                    'month': 2,
                    'year': 2024,
                  },
                ),
              ]);
            }
            // Verify both dispatches completed before this second sendMessage.
            expect(
              completedCount,
              2,
              reason: 'both tool calls must resolve before next sendMessage',
            );
            return _textResponse('all done');
          },
        );

        expect(completedCount, 2);
      },
    );

    // -----------------------------------------------------------------------
    // 10. Iteration counter: 6th sendMessage is the summarize prompt
    // -----------------------------------------------------------------------
    test(
      'iteration counter: exactly 6th sendMessage is the summarize prompt',
      () async {
        final dispatcherSpy = _FixedDispatcher(fixedResult: {'ok': true});
        final controller = ToolLoopController(dispatcher: dispatcherSpy);

        int callCount = 0;
        Content? sixthContent;

        await controller.execute(
          userMessage: 'start',
          sendMessage: (content) async {
            callCount++;
            if (callCount < 6) {
              // Calls 1–5: return a FunctionCall to keep the loop going.
              return _functionCallResponse([
                (
                  name: 'generate_monthly_report',
                  args: {
                    'month': callCount,
                    'year': 2024,
                  },
                ),
              ]);
            }
            // Call 6: must be the summarize prompt.
            sixthContent = content;
            return _textResponse('summary result');
          },
        );

        expect(callCount, 6);
        expect(sixthContent, isNotNull);
        final part = sixthContent!.parts.first as TextPart;
        expect(part.text, contains('tóm tắt'));
      },
    );
  });
}

// ---------------------------------------------------------------------------
// _TrackingDispatcher: wraps dispatch() with a custom callback
// ---------------------------------------------------------------------------

class _TrackingDispatcher extends ToolDispatcher {
  final Future<Map<String, Object?>> Function(String, Map<String, Object?>)
  onDispatch;

  _TrackingDispatcher({required this.onDispatch})
    : super(
        generateTimeSlots:
            ({
              required startTime,
              required endTime,
              required intervalMinutes,
            }) => [],
        getMoodEntries: (_, __, ___) async => [],
        userId: _userId,
      );

  @override
  Future<Map<String, Object?>> dispatch(
    String toolName,
    Map<String, Object?> args,
  ) async {
    return onDispatch(toolName, args);
  }
}
