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

An approved complete variant has the path `assets/avatar_prototype/{selection.artworkKey}.webp`. Incomplete combinations will continue to show the pending state until created; do not fabricate the missing variants with arbitrary overlays.

### Installing the two review candidates

A separate downloadable `brim_prototype_asset_pack.zip` was prepared for the quality trial; it is **not committed to GitHub** because GitHub's text-file editing workflow does not upload binary assets. It contains the two violet/gentle variants above and is **candidate artwork, not final approved art**.

After transferring the ZIP into the **repository root in Codespaces**, run:

```bash
python3 tools/install_brim_prototype_art.py brim_prototype_asset_pack.zip
flutter pub get
flutter run --profile -t lib/avatar/brim_lab_main.dart -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

The installer validates the file names and WebP headers, copies the exact candidates to their expected directories and idempotently registers the asset directory in `pubspec.yaml`. The resulting `assets/` and `pubspec.yaml` changes are local until explicitly committed. No production release should be done before quality and tests pass.

For this trial only **Violet + Gentle + None/Scarf** has candidate art. All other selections will continue to display an honest placeholder. Review geometry/edge quality and 48px clarity first.

After the scarf pair passes the large and 48px test, add the additional colourways/expressions or consider an intentionally curated smaller set. The lack of cross-character reusable geometry must be accounted for in production estimates.


### Second colourway trial — Blue Brim (14 November 2026)

The founder agreed to trial two separately generated complete Blue + Gentle illustrations, one without an accessory and one with the scarf. They were resized to fit a common 512×512 transparent canvas; **the colourway remains experimental**. Comparing with Violet shows differences in facial geometry, eye expression, and feather/scale details, so this is deliberately an *honest consistency test*, not proof of a single pixel-identical character merely recoloured.

Use the separately provided `Natter_Brim_Blue_Artwork_Test_Pack.zip`. Upload it into your Codespaces repository's `assets/` folder as with the Violet ZIP, then run from the Natter repository root:

```bash
python3 tools/install_brim_prototype_art.py assets/Natter_Brim_Blue_Artwork_Test_Pack.zip
flutter pub get
flutter run --profile -t lib/avatar/brim_lab_main.dart -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

The same installer now accepts either a complete Violet pair or a complete Blue pair. It refuses half-pairs, validates WebP containers, preserves the previously installed colourway, and only changes local asset files and (if needed) the asset declaration. Don't commit or merge the downloaded ZIP.

With `Gentle` selected, compare Violet ↔ Blue for **None** and **Scarf**. Inspect face size, anatomy, pose, wing contours, scarf fit and 48px portraits, including first-switch smoothness. Mint, Delighted and Satchel will remain intentionally unillustrated.

**Production gate:** If the blue look seems to morph into a different dragon, that does *not* pass the consistency test. Prefer artist-controlled recolouring of approved identical geometry or restrict the number of variants. Don't begin producing six creatures × 18 combinations based on this trial.

### Replacement Blue artwork test — after failed independent redraw

**The independently generated Blue/None and Blue/Scarf pair failed the on-device continuity test.** Do not continue evaluating or reusing that pair as evidence of a viable avatar pipeline. They appeared to change Brim's size and geometry, and their blue tones differed.

A new replacement pair was created by carefully recolouring each of the already-approved Violet source illustrations. For each exact accessory state, the Blue output has the **same dimensions, transparent silhouette and pixel-position layout** as its corresponding Violet source. Both share a controlled colour mapping. A QA comparison preview accompanies the pack.

Download `Natter_Brim_Blue_Pixel_Locked_Test_Pack.zip`, upload the ZIP into Codespaces `assets/`, then, with the Brim Lab stopped:

```bash
python3 tools/install_brim_prototype_art.py assets/Natter_Brim_Blue_Pixel_Locked_Test_Pack.zip
flutter pub get
flutter run --profile -t lib/avatar/brim_lab_main.dart -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

This deliberately **overwrites only** the existing Blue/None and Blue/Scarf test artwork, leaving both Violet source files intact. The lab code need not change. For a consistent comparison, select Gentle, then switch Violet ↔ Blue for None, and repeat for Scarf.

**Important limits:** This fixes size and anatomy *across colour changes* because the transparent masks are identical. It cannot correct slight differences between the existing Violet None and Scarf masters, and selective recolouring can create minor colour-edge artefacts. The replacement is another **candidate**, not approved production art. If it still fails visual scrutiny, stop expanding palettes and consider professionally layered artwork.

## No-impact guarantee

Production `lib/main.dart`, navigation, child onboarding, Firestore permissions, family messaging, and the GitHub Pages deployment workflow are **unchanged** by the lab. This branch is not ready for merge. The separate offline delivery-state issue is [#17](https://github.com/leetreays/Natter/issues/17).
