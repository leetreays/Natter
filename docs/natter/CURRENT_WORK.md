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
- **Current trial:** Violet/Playful/None (wink, no tongue) and Violet/Cheeky/None (tongue-out) are now prepared as localised edits of the original Friendly master with the same canvas, alpha and unchanged body/silhouette. The Cheeky tongue is subtle at 48px; founder's on-device review is required before approval or replication to other accessories.
- The isolated Brim Lab now offers three visible options: Friendly (still internally `gentle` for compatibility), Playful and Cheeky. The old Cheerful/`delighted` choice is no longer shown, but older installed files are untouched. This is a trial: some colour/expression/accessory choices intentionally lack artwork and show an honest placeholder.
- The installer accepts standalone Playful/Cheeky candidate images, keeping earlier safety checks for complete Gentle/Delighted None+Scarf pairs. A `Natter_Brim_Violet_Playful_Cheeky_Trial_Pack.zip` has been prepared outside GitHub for the founder to upload. Automated installer and Flutter changes need to be tested in Codespaces.
- Next after in-app approval: apply the approved facial treatments to existing Scarf and Satchel variants, extend to Blue/Mint with controlled palette operations. Do not independently regenerate the full dragon.
- Keep candidate WebP images in the local Codespaces checkout until approved; untracked artwork ZIPs and locally modified `pubspec.yaml` must not be discarded. Avoid broad changes to `main.dart`.
- The GitHub integration workflow is direct code commits by the assistant, followed by short `git pull`, test and launch commands for the founder.

## Next verification

1. Upload `Natter_Brim_Violet_Playful_Cheeky_Trial_Pack.zip` into Codespaces `assets/`, then `git pull --ff-only`.
2. Run `python3 tools/test_install_brim_prototype_art.py`, install the ZIP with `python3 tools/install_brim_prototype_art.py assets/*Playful_Cheeky*.zip`, and run `flutter test test/brim_avatar*`.
3. Launch the isolated Avatar Lab and compare Violet + None: Friendly ↔ Playful ↔ Cheeky at hero and 48px. Inspect facial seams and whether the tongue is visible enough, with no changes to the body when switching.
4. Only if both expressions pass, propagate these edits to Scarf/Satchel, then Blue/Mint; finish all 27 combinations.
5. Do not merge the avatar branch or add shared avatar persistence until full artwork and security/visibility gates pass.

See `docs/natter/BRIM_LAB.md` and `docs/natter/AVATAR_SYSTEM.md` for technical background.
