#!/usr/bin/env python3
from pathlib import Path
import subprocess

EXPECTED_HEAD = "180079104febef071bef4ff3e7a82226a39ff738"

root = Path.cwd()
rules_path = root / "firestore.rules"
main_path = root / "lib/main.dart"
test_path = root / "test/firestore.rules.test.js"

if not rules_path.exists() or not main_path.exists() or not test_path.exists():
    raise SystemExit("ABORT: run this from the Natter repository root.")

head = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
if head != EXPECTED_HEAD:
    raise SystemExit(
        f"ABORT: expected HEAD {EXPECTED_HEAD}, found {head}. No files changed."
    )

rules = rules_path.read_text()
main = main_path.read_text()
tests = test_path.read_text()

required_markers = [
    "function validBlockedByChildIdsUpdate(conversation, affectedKeys)",
    "function validTypingChangeAt(conversation, index)",
    "function validConversationUpdate(conversation)",
    "let affectedKeys =",
    "allow update: if validConversationUpdate(resource.data);",
]
for marker in required_markers:
    if marker not in rules:
        raise SystemExit(
            f"ABORT: expected second-pass marker not found: {marker}. No files changed."
        )

if "function typingStateUnchanged(conversation)" in rules:
    raise SystemExit("ABORT: third-pass typing optimisation already appears present.")

if "await FirebaseFirestore.instance.runTransaction((transaction) async {" not in main:
    raise SystemExit(
        "ABORT: transactional clearTyping() marker not found. No files changed."
    )

# The second-pass test corrections must already be present. This script deliberately
# does not touch tests or Dart; it only optimises Firestore rule evaluation.
for marker in [
    "typingAt: serverTimestamp(),",
    "describe('conversation typing ownership'",
    "transactional stale clear preserves the newer participant state",
]:
    if marker not in tests:
        raise SystemExit(
            f"ABORT: expected applied typing-test marker not found: {marker}. No files changed."
        )


def replace_function_block(text, start_marker, end_marker, replacement):
    start = text.find(start_marker)
    if start == -1:
        raise SystemExit(f"ABORT: start marker not found: {start_marker}. No files changed.")
    end = text.find(end_marker, start)
    if end == -1:
        raise SystemExit(f"ABORT: end marker not found: {end_marker}. No files changed.")
    if text.find(start_marker, start + 1) != -1:
        raise SystemExit(f"ABORT: duplicate start marker: {start_marker}. No files changed.")
    return text[:start] + replacement + text[end:]


block_replacement = """    function blockedByChildIdsUnchanged(conversation) {
      return request.resource.data.get('blockedByChildIds', [])
        == conversation.get('blockedByChildIds', []);
    }

    function validBlockedByChildIdsUpdate(conversation) {
      return blockedByChildIdsUnchanged(conversation)
        || validSelfBlockedByChildIdsChangeAt(conversation, 0, 1)
        || validSelfBlockedByChildIdsChangeAt(conversation, 1, 0);
    }

"""

rules_new = replace_function_block(
    rules,
    "    function validBlockedByChildIdsUpdate(conversation, affectedKeys) {",
    "    function isMessageSenderAt(conversation, message, index) {",
    block_replacement,
)


typing_replacement = """    function validTypingChangeAt(conversation, index) {
      return (
          (
            request.resource.data.get('typingChildId', null)
              == conversation.participantChildIds[index]
            && request.resource.data.get('typingAt', null) == request.time
          )
          || (
            conversation.get('typingChildId', null)
              == conversation.participantChildIds[index]
            && request.resource.data.keys().hasAll([
              'typingChildId',
              'typingAt'
            ])
            && request.resource.data.typingChildId == null
            && request.resource.data.typingAt == null
          )
        )
        && isLinkedParticipantAt(conversation, index);
    }

    function typingStateUnchanged(conversation) {
      return request.resource.data.get('typingChildId', null)
          == conversation.get('typingChildId', null)
        && request.resource.data.get('typingAt', null)
          == conversation.get('typingAt', null);
    }

    function validConversationUpdate(conversation) {
      return !request.resource.data.diff(resource.data).affectedKeys().hasAny([
          'friendshipId',
          'participantChildIds',
          'participantParentIds',
          'participantNames',
          'status',
          'createdAt'
        ])
        && validBlockedByChildIdsUpdate(conversation)
        && (
          (
            typingStateUnchanged(conversation)
            && isLinkedConversationParticipant(conversation)
          )
          || validTypingChangeAt(conversation, 0)
          || validTypingChangeAt(conversation, 1)
        );
    }

"""

rules_new = replace_function_block(
    rules_new,
    "    function validTypingChangeAt(conversation, index) {",
    "    function childLinkageUnchanged() {",
    typing_replacement,
)

if rules_new == rules:
    raise SystemExit("ABORT: no rules changes produced.")

# Final guards: the second-pass affectedKeys plumbing should be gone and the
# third-pass normalised comparisons should be present exactly once.
for forbidden in [
    "function validBlockedByChildIdsUpdate(conversation, affectedKeys)",
    "let affectedKeys =",
    "validBlockedByChildIdsUpdate(conversation, affectedKeys)",
]:
    if forbidden in rules_new:
        raise SystemExit(
            f"ABORT: stale second-pass rule marker remains: {forbidden}. No files changed."
        )

for required in [
    "function blockedByChildIdsUnchanged(conversation)",
    "function typingStateUnchanged(conversation)",
    "function validBlockedByChildIdsUpdate(conversation)",
    "allow update: if validConversationUpdate(resource.data);",
]:
    if rules_new.count(required) != 1:
        raise SystemExit(
            f"ABORT: expected exactly one third-pass marker: {required}. No files changed."
        )

rules_path.write_text(rules_new)

print("Applied third-pass typing expression-budget optimisation.")
print("Modified only: firestore.rules")
print("lib/main.dart unchanged.")
print("test/firestore.rules.test.js unchanged.")
print("Next: npm run test:firestore-rules")
