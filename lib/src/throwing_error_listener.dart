import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';

final class ThrowingErrorListener extends AnalysisErrorListener {
  @override
  void onError(AnalysisError error) {
    throw error;
  }
}
