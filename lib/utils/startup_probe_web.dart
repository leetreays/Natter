import 'dart:js_interop';

// Development-only bridge into the Codespaces browser timing panel.
// The JavaScript receiver is a no-op outside the approved preview host.
@JS('natterStartupMilestone')
external void _natterStartupMilestone(String milestone);

void reportStartupMilestone(String milestone) {
  try {
    _natterStartupMilestone(milestone);
  } catch (_) {
    // Never allow diagnostics to affect authentication or routing.
  }
}
