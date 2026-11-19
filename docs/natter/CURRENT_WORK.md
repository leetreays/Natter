# Natter — Current Work

**Last updated:** 19 November 2026

## Active task

Brim V1 avatar feasibility and artwork-quality validation on `feature/child-avatar-identity`. Brim is the first of six proposed distinct child avatar character types. The target is three colours (Violet, Blue, Mint), three expressions (Friendly, Playful, Cheeky) and three accessory states (None, Scarf, Satchel), giving **27 combinations**. This is not yet a production avatar system.

## Latest verified progress

- Family Connections parent-child messaging and unread state were previously tested end-to-end; the production-facing app is not being changed by this avatar work.
- The avatar lab already allows users to pick colour, expression and accessory while deliberately **not** saving identity to Firestore.
- The 280ms crossfade was removed; the 9 existing Flutter avatar tests passed in Codespaces and the founder confirmed instant switching looks right.
- Violet Friendly (internal `gentle` ID) with no accessory and with scarf is available as local candidate artwork, with approved Blue/Mint colourway variants also previously installed locally.
- **Violet / Friendly / Satchel passed in-app founder visual review on 19 November 2026:** no visible morphing or inconsistent switching in the large preview; 48px portrait remains recognisable. The satchel is barely visible at 48px because the existing portrait crop prioritises the face. This is acceptable and no new crop or zoom-out is requested. This constitutes an approved working combination, not approval of the remaining 26 combinations.
- The standalone `Natter_Brim_Violet_Satchel_Trial_Pack.zip` was installed and visually tested in Codespaces; the binary asset remains in the founder's local checkout rather than committed to GitHub.
- The GitHub ZIP installer now accepts a single satchel candidate while preserving complete-pair validation for None and Scarf. Installer regression tests have been committed; their execution result has not yet been provided in this chat.

## Current approach

- Prefer careful local compositing onto a fixed Brim master, reusing geometry and transparency. Do not independently redraw entire Brim illustrations for each selection, which caused visible jumps.
- **Next:** prepare Violet Playful (wink, no tongue) and Cheeky (tongue out) as pixel-locked facial edits to the approved Violet/Friendly/None master. Keep face recognisable at 48px. Then apply the same approved facial treatments to existing Scarf and Satchel variants, and extend to Blue/Mint using controlled palette operations. Don't create unrelated whole-character redraws.
- Keep candidate WebP images in the local Codespaces checkout until approved; untracked artwork ZIPs and locally modified `pubspec.yaml` must not be discarded. Avoid broad changes to `main.dart`.
- The GitHub integration workflow is direct code commits by the assistant, followed by short `git pull`, test and launch commands for the founder.

## Next verification

1. Prepare two distinctly different **Violet/None** facial expressions: Playful = wink without tongue; Cheeky = tongue-out grin. Verify both preserve the existing body/pose/silhouette.
2. Assess both expression changes at hero and 48px preview sizes before expanding to Scarf and Satchel.
3. Update the asset installer, lab expression model, existing test expectations and code directly in GitHub only when the candidate expression pack is ready; founder runs short pull/test commands.
4. Extend expressions to Scarf and Satchel, then to Blue/Mint; verify the complete 27-image matrix and artwork package before merging.
5. Do not merge the avatar branch or add shared avatar persistence until full artwork and security/visibility gates pass.

See `docs/natter/BRIM_LAB.md` and `docs/natter/AVATAR_SYSTEM.md` for technical background.
