# Brim Avatar Lab — isolated Flutter prototype

**Status:** interactive controls implemented; artwork feasibility **not yet passed**. This is a standalone lab, not part of the deployed Natter child application.

## Why this exists

The approved direction is a small, premium, original fantasy-creature system, using Natter's existing child-facing theme. The difficult question is whether colour variants and accessories can retain the quality of the finished concept illustrations in a working app.

The prototype imports `NatterChildBackground`, `NatterChildSurface`, `NatterChildTheme`, `NatterChildPrimaryButton` and `NatterBrand` from `lib/main.dart`. It does not rebuild or imitate the Natter design system.

## Run it in Codespaces

Check that your local worktree is clean before changing branches:

```bash
git status --short
git fetch origin
git switch feature/child-avatar-identity
git pull --ff-only origin feature/child-avatar-identity
```

Run the two new test files:

```bash
flutter test test/brim_avatar_selection_test.dart test/brim_avatar_lab_test.dart
```

Then open a **separate** isolated app using port 8080 (stop any previous `flutter run` first):

```bash
flutter run --profile -t lib/avatar/brim_lab_main.dart -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

Use the existing Codespaces port-forwarded preview link. This lab deliberately avoids Firebase initialisation and does not change saved child profiles.

## What works today

- Choose Violet, Blue or Mint.
- Choose Gentle or Delighted.
- Choose None, Scarf or Satchel.
- Model supports 18 distinct stable complete-artwork keys and can serialise selections.
- Large and 48px previews request the **same choice**.
- Selection controls can be exercised without saving anything to Firestore.
- Shared child branding is used rather than separately recreated mockup styling.

## What intentionally does **not** work today

**No production-grade Brim art is installed.** Preview spaces show a clearly labelled asset-pending state. This is not a bug and should not be judged as the character art. The previous AI-generated concept boards were flattened compositions; they are not fitted and interchangeable character assets.

## Artwork format for the feasibility test

Before evaluating visual quality, produce **at least two approved, complete Brim renderings**:

- `assets/avatar_prototype/brim_v1_violet_gentle_none.webp`
- `assets/avatar_prototype/brim_v1_violet_gentle_scarf.webp`

They must share the same canvas, scale, anatomy and pose; the scarf variant must have credible front/back occlusion and matching shadows and highlights. Export with transparent backgrounds and without in-image titles, scenic panels or borders.

An approved complete variant has the path `assets/avatar_prototype/{selection.artworkKey}.webp`. Register the folder as an asset directory in `pubspec.yaml` **when the first real art files are added**. Incomplete combinations will continue to show the pending state until created; do not fabricate the missing variants with arbitrary overlays.

After the scarf pair passes the large and 48px test, add the additional colourways/expressions or consider an intentionally curated smaller set. The lack of cross-character reusable geometry must be accounted for in production estimates.

## No-impact guarantee

Production `lib/main.dart`, navigation, child onboarding, Firestore permissions, family messaging, and the GitHub Pages deployment workflow are **unchanged** by the lab. This branch is not ready for merge. The separate offline delivery-state issue is [#17](https://github.com/leetreays/Natter/issues/17).
