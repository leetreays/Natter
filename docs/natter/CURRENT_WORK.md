# Natter — Current Work

**Last updated:** 18 November 2026

## Active task

Brim V1 avatar feasibility and artwork-quality validation on `feature/child-avatar-identity`. Brim is the first of six proposed distinct child avatar character types. The target is three colours (Violet, Blue, Mint), three expressions (Friendly, Playful, Cheeky) and three accessory states (None, Scarf, Satchel), giving **27 combinations**. This is not yet a production avatar system.

## Latest verified progress

- Family Connections parent-child messaging and unread state were previously tested end-to-end; the production-facing app is not being changed by this avatar work.
- The avatar lab already allows users to pick colour, expression and accessory while deliberately **not** saving identity to Firestore.
- The 280ms crossfade was removed; the 9 existing Flutter avatar tests passed in Codespaces and the founder confirmed instant switching looks right.
- Violet Friendly (internal `gentle` ID) with no accessory and with scarf is available as local candidate artwork, with approved Blue/Mint colourway variants also previously installed locally.
- The founder visually approved the pixel-preserving Violet/Friendly/Satchel instant-switching comparison as sufficient to proceed to **in-app trial**, not final approval.
- A standalone `Natter_Brim_Violet_Satchel_Trial_Pack.zip` was prepared separately from GitHub and needs to be uploaded to Codespaces `assets/`.
- The GitHub ZIP installer now accepts a single satchel candidate while preserving complete-pair validation for None and Scarf. Installer regression tests have been committed but need execution in Codespaces.

## Current approach

- Prefer careful local compositing onto a fixed Brim master, reusing geometry and transparency. Do not independently redraw entire Brim illustrations for each selection, which caused visible jumps.
- Work sequentially: Violet/Friendly/Satchel in the real lab; then Violet's clear Playful (wink, no tongue) and Cheeky (tongue out) expressions with None/Scarf/Satchel; then extend approved artwork to Blue and Mint using controlled palette operations.
- Keep candidate WebP images in the local Codespaces checkout until approved; untracked artwork ZIPs and locally modified `pubspec.yaml` must not be discarded. Avoid broad changes to `main.dart`.
- The GitHub integration workflow is direct code commits by the assistant, followed by short `git pull`, test and launch commands for the founder.

## Next verification

1. Upload the satchel ZIP to Codespaces `assets/`; pull the updated feature branch.
2. Run `python3 tools/test_install_brim_prototype_art.py` and install the ZIP with `python3 tools/install_brim_prototype_art.py assets/Natter_Brim_Violet_Satchel_Trial_Pack.zip`.
3. Run `flutter test test/brim_avatar*`, then the isolated avatar lab.
4. With Violet/Friendly selected, switch None ↔ Satchel and Scarf ↔ Satchel, checking visual stability at full size and 48px.
5. Do not merge the avatar branch or add shared avatar persistence until full artwork and security/visibility gates pass.

See `docs/natter/BRIM_LAB.md` and `docs/natter/AVATAR_SYSTEM.md` for technical background.
