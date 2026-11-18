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

### Third colourway — repeatable Mint trial (15 November 2026)

**Mint artwork candidates prepared and locally checked; founder's on-device visual review is still pending.** The generator is committed as `tools/recolour_brim_palette.py`.

Rather than asking an image model to redraw Brim, the generator applies **one identical selective recolour algorithm** to the accepted Blue/Gentle/None and Blue/Gentle/Scarf files. It maps clearly blue/cyan material to a seafoam/mint shade and protects cream horns, belly plates, teeth and warm highlights. It changes RGB values only; the source canvas, alpha and silhouette remain exactly the same for each accessory state.

**Pack for easy phone upload:** `Natter_Brim_Mint_Artwork_Test_Pack.zip`. Upload the ZIP to the Codespaces repository's `assets/` folder, stop the prior Flutter process and run:

```bash
git pull --ff-only origin feature/child-avatar-identity
python3 tools/install_brim_prototype_art.py assets/Natter_Brim_Mint_Artwork_Test_Pack.zip
flutter pub get
flutter test test/brim_avatar_selection_test.dart test/brim_avatar_lab_test.dart
flutter run --profile -t lib/avatar/brim_lab_main.dart -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

The installer now accepts **Violet, Blue or Mint complete pairs**, rejecting incomplete ZIPs without modifying installed assets. The app lab preloads all six test images (3 colours × 2 accessories) for smoother first switches.

**Repeatable developer path (optional):** Once the accepted Blue/Gentle pair is installed, `python3 -m pip install Pillow` (development environment only), then `python3 tools/recolour_brim_palette.py`. This recreates Mint assets in-place without relying on the ZIP. Pillow is **not** a Flutter app dependency. This script does *not* recreate the earlier Blue-from-Violet algorithm, which was an experimental separately prepared master; fully repeatable production palette sourcing still needs formalisation.

**Acceptance test:** Switch between Violet, Blue and Mint with Gentle selected, first None then Scarf. Look for colour spill into cream details, imperfect edges, different shades between accessory states, jumps in pose/scale, 48px recognisability and first-switch flicker. Retain prior acceptance of Violet/Blue only; don't accept Mint until the founder reviews the actual app.

**Limits:** The 2 accessory master images have existing small framing differences. Controlled recolouring cannot fix that. Mint does not demonstrate editing an expression or fitting new accessories. No merge of Draft PR #18 yet.

### Delighted expression trial — six complete previews (15 November 2026)

The first controlled **Delighted** expression trial is now packaged as `Natter_Brim_Delighted_Trial_Pack.zip`. There are six 512×512 transparent candidate images: Violet/Blue/Mint × None/Scarf, named `brim_v1_<colour>_delighted_<accessory>.webp`. The ZIP includes a side-by-side Gentle vs Delighted preview and QA hashes.

**Important limitation:** Freshly generating a Delighted dragon independently changed the character's shape/pose, which failed our consistency requirement, so the shipped trial candidates are instead generated by *localised facial deformation* of the accepted Gentle art (gentle eye-squint, lifted cheeks/smile corners). Transparency, canvas, wings, body pose, scale, colours and scarf are pixel-locked. Because Brim already smiles enthusiastically in Gentle, the distinction is **subtle**. This is an experiment to discover whether a controlled expression can be recognisable without painterly damage, not an approved second expression.

Phone installation, once the downloaded ZIP has been uploaded to `assets/`:

```bash
git pull --ff-only origin feature/child-avatar-identity
python3 tools/install_brim_prototype_art.py assets/Natter_Brim_Delighted_Trial_Pack.zip
flutter pub get
flutter test test/brim_avatar_selection_test.dart test/brim_avatar_lab_test.dart
flutter run --profile -t lib/avatar/brim_lab_main.dart -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

The installer now accepts an entire `None + Scarf` pair for **either Gentle or Delighted**, per colour, rejecting incomplete pair uploads without writing any assets. These new files do not replace the 6 existing Gentle assets. The Lab preloads all 12 available candidates for smooth switching; Satchel combinations remain unillustrated.

**Acceptance questions:** At each colourway and with the accessory unchanged, toggle Gentle ↔ Delighted. Can a child tell the faces apart in the hero preview and especially at 48px? Do eyes/cheeks/smile change without distortion, blocky retouching, flicker, or size shifts? Repeat with scarf. If the expression difference is too subtle or distortions are visible, **reject the candidate and revisit layered facial artwork**, rather than declaring the pipeline production-ready.

Candidates remain solely in the local Codespaces checkout until explicitly committed; PR #18 stays Draft. Do not merge these images or onboarding changes as part of this evaluation.

### Expression review — Cheerful + subtle crossfade (15 November 2026)

The founder tested the localised Gentle → Delighted facial artwork. Its slightly widened smile is not expressive enough to justify the name **Delighted**. No new expression artwork has been approved.

To test the founder's animation suggestion without generating another mismatched creature:

- The **visible label** in the isolated Brim Lab is now **Cheerful** (a more accurate description of the small extra smile).
- The **internal key remains `delighted`** in the selection enum and asset filenames. This avoids invalidating the six already installed proof-of-concept WebPs; any eventual production rename must include deliberate data/asset migration.
- Both the 220px hero and 48px circular portrait now use a **280ms opacity crossfade** via Flutter `AnimatedSwitcher` when changing **expression**. Colour or accessory changes retain their previous gapless image-swap behaviour; the animation never changes Brim's pixel geometry.
- A reduced-motion device preference disables the transition. The crossfade is not a facial rig or frame-by-frame animation: it blends the two already-fitted complete illustrations, which might appear to smile modestly.
- A new widget test covers the outgoing/incoming preview frames. **Flutter tests and actual on-device transition smoothness are still pending verification** following these edits.

**Codespaces trial:** Stop Flutter with `q`, then:

```bash
git pull --ff-only origin feature/child-avatar-identity
flutter test test/brim_avatar_selection_test.dart test/brim_avatar_lab_test.dart
flutter run --profile -t lib/avatar/brim_lab_main.dart -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

The six installed `*_delighted_*.webp` candidate assets remain in Codespaces; **no new ZIP/upload required**. Keep one colour and accessory selected, toggle Gentle ↔ Cheerful repeatedly and observe both the hero and 48px icon. Confirm whether the fade looks like a natural growing/relaxing smile, whether there's ghosting/jumping, and whether the expression feels meaningfully different. If it's still too subtle, stop changing labels/transition timing and revisit proper layered facial artwork (eyes, cheeks, mouth).

## No-impact guarantee

Production `lib/main.dart`, navigation, child onboarding, Firestore permissions, family messaging, and the GitHub Pages deployment workflow are **unchanged** by the lab. This branch is not ready for merge. The separate offline delivery-state issue is [#17](https://github.com/leetreays/Natter/issues/17).


### Violet / Friendly / Satchel — bounded composite trial (18 November 2026)

The founder approved the **instant-switching visual comparison** of a new Violet satchel review candidate. This is an approval to test it inside the app, **not** final production art approval.

- Source of truth: the existing 512×512 Violet/Gentle/None artwork. The lab now displays the friendly expression label as **Friendly**, while retaining the internal `gentle` artwork ID until the complete expression migration.
- The satchel and strap were composited from the candidate into a bounded area of the established Brim master. The finished WebP preserves the original alpha channel, canvas and silhouette, with visible pixels outside the accessory mask untouched.
- The review ZIP is named `Natter_Brim_Violet_Satchel_Trial_Pack.zip`; its single asset is `assets/avatar_prototype/brim_v1_violet_gentle_satchel.webp`. **This binary ZIP is not stored in GitHub**; transfer the separately supplied pack into the Codespaces `assets/` folder.
- The installer now accepts a standalone Satchel asset, while continuing to require complete None/Scarf pairs for those existing expressions. It validates the ZIP's WebP headers before writing assets and doesn't remove previous variants.
- The standalone Brim Lab already exposes Satchel as a selection. Its missing-art state will be replaced by this asset when installed. No production child profile or Firestore data is changed.

From the feature branch in Codespaces, with local candidate artwork preserved:

```bash
git pull --ff-only
python3 tools/test_install_brim_prototype_art.py
python3 tools/install_brim_prototype_art.py assets/Natter_Brim_Violet_Satchel_Trial_Pack.zip
flutter test test/brim_avatar_selection_test.dart test/brim_avatar_lab_test.dart
flutter run --profile -t lib/avatar/brim_lab_main.dart -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

**Acceptance:** switch Violet/Friendly between None, Scarf and Satchel at hero and 48px sizes. Look for scale jumps, flicker, strap clipping, unintended pixels and good legibility. Blue/Mint Satchel assets remain pending; Playful and Cheeky remain artwork work-in-progress. Do not merge the avatar prototype into `main` until the full artwork quality gate and cross-role identity rules are reviewed.
