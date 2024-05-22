import 'package:analyzer/error/error.dart' show AnalysisError;
import 'package:analyzer/error/listener.dart' show AnalysisErrorListener;

final class ThrowingErrorListener extends AnalysisErrorListener {
  @override
  void onError(AnalysisError error) {
    throw error;
  }
}
