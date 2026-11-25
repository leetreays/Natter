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

## 19 November — Violet expression and accessory milestone

- Founder tested Violet / None in Avatar Lab using Friendly, Playful and Cheeky, reporting **all three render and switch seamlessly**, with no visible image jumping. Their screenshots confirm the three expressions are distinctive at full size and recognisable at 48px. This is visual acceptance of the Violet/None trio; do not infer tests for other combinations.
- Four new **Violet accessory-expression trial images** have been prepared by compositing the approved facial edits onto the existing Scarf and Satchel artwork (Playful/Scarf, Cheeky/Scarf, Playful/Satchel, Cheeky/Satchel). The scarf needs foreground occlusion at the cheek/tongue edge; mask was refined before packaging. Canvas and each accessory master's transparency/visible silhouette are unchanged, and pixels outside the facial mask remain untouched.
- Review ZIP prepared separately as `Natter_Brim_Violet_Expression_Accessories_Trial_Pack.zip`, containing only these four WebPs. It is **not** committed to GitHub and requires founder installation in Codespaces.
- `lib/avatar/brim_lab_main.dart` now precaches all nine Violet candidate combinations and the candidate-status text reflects this coverage; Blue/Mint expansion has not begun. Installer already supports standalone Playful and Cheeky trial assets.
- **Next verification:** upload the four-asset pack to Codespaces `assets/`, pull branch, install using `python3 tools/install_brim_prototype_art.py assets/*Expression_Accessories*.zip`, run `flutter test test/brim_avatar*`, launch isolated lab and test Violet across three expressions × three accessories at full and 48px. Verify scarf/tongue overlap and absence of morphing before approving Violet nine.
- **After Violet passes:** derive the Blue and Mint variants from approved corresponding Violet source artwork using controlled recolouring (18 remaining combinations), not independent whole-character generation. Keep product avatar persistence/permissions separate from the art trial.


## 19 November — Cheeky/Satchel strap repair (awaiting in-app check)

- Founder tested the Violet nine-combination trial and reported eight combinations visually correct, with one defect: Violet/Cheeky/Satchel had the upper leather strap missing at Brim's viewer-right upper chest/shoulder. The screenshot showed an intact strap on Playful/Satchel for comparison.
- A **single-asset corrective WebP** was prepared by copying the missing strap pixels from the approved Violet/Friendly/Satchel reference into the Cheeky/Satchel candidate. The unchanged Cheeky tongue-out face and lower satchel/buckle remain intact.
- The fixed 512×512 image has unchanged alpha, canvas, and silhouette. Exactly 1,024 visible pixels differ from the previous Cheeky/Satchel candidate, all inside the local repair rectangle x=336..374, y=253..296; visible pixels outside remain unchanged.
- Delivered as `Natter_Brim_Violet_Cheeky_Satchel_Strap_Fix.zip` with exactly `assets/avatar_prototype/brim_v1_violet_cheeky_satchel.webp`. This ZIP is a local conversation artifact, not committed to GitHub. The existing standalone expression installer supports it without a new code change.
- **Next:** upload the ZIP into Codespaces `assets/`, install via `python3 tools/install_brim_prototype_art.py assets/*Cheeky_Satchel_Strap_Fix.zip`, run `flutter test test/brim_avatar*`, and relaunch the isolated Brim Lab. Check Violet → Cheeky → Satchel and switch to Playful → Satchel. If the strap stays intact and the portraits look right, approve the full Violet nine and proceed to Blue/Mint derivation.


## 19 November — second Cheeky/Satchel strap correction (V2, pending phone verification)

- The founder reported the original strap gap was still visible after the first repair ZIP. This was traced to a **faulty repair mask**, not a confirmed Flutter rendering bug: the first correction restored lower leather pixels at y≈253–296 but missed the upper shoulder section around y≈227–263.
- Re-inspected the original Violet/Friendly/Satchel and Cheeky/Satchel 512×512 WebPs and compared the shoulder at matching pixel coordinates. A new local composite restores the **entire upper strap** from the approved Friendly/Satchel master while retaining the Cheeky tongue and original transparency.
- The new pack is `Natter_Brim_Violet_Cheeky_Satchel_Strap_Complete_V2.zip` with one `assets/avatar_prototype/brim_v1_violet_cheeky_satchel.webp` asset. It is a separate downloadable ZIP, **not in GitHub**. It should replace only the affected local asset.
- Verified a continuous strap in the local 1:1 comparison; the new asset is 512×512, has the same alpha channel and differs from the old candidate in 3,135 visible pixels restricted to x=320..398, y=227..296.
- Expected installed asset SHA-256: `cab0c4854fe085fc8f3bd5d7a62cc9428d60e793eff4aefe489b5a5fed1cc385`.
- **Next:** founder uploads the V2 ZIP into `assets/`, installs using exact filename, verifies SHA-256 with `sha256sum assets/avatar_prototype/brim_v1_violet_cheeky_satchel.webp`, re-runs the Flutter lab after stopping any previous server and refreshes the preview. Only then approve Violet's final nine combinations; earlier code and artwork remain untouched.


## 19 November — Violet Brim set fully approved

- The founder installed and tested the corrected `Natter_Brim_Violet_Cheeky_Satchel_Strap_Complete_V2.zip` in Codespaces and reported **“All done. And all perfect.”** The previously missing upper strap is visually resolved.
- **All 9 Violet Brim variants now pass the founder's in-app visual check:** Friendly, Playful and Cheeky × None, Scarf and Satchel. This includes instant image switching and small 48px portrait readability. Do not reopen Violet design in the absence of a new reproducible defect.
- Violet artwork remains local to Codespaces (not committed to GitHub). Preserve its candidate WebPs and approved V2 patch. This visual approval does **not** by itself confirm production persistence, friend-visible avatar data, release readiness, or a full 27-image test run.
- **Next art priority:** create and test the 9 Blue and 9 Mint variants from the approved Violet masters. Reuse previously accepted palette details (Blue cyan accents; Mint with darker-blue/yellow accents; consistent pinkish tongue) and the existing pixel-locked recolouring approach. Do not regenerate Brim's anatomy. First verify the Blue/Mint Friendly references still match the approved colour direction, then apply that direction to expressions and accessories. Test the full 27-combination matrix before production integration.
- Maintain the established workflow: assistant edits GitHub files and prepares artwork packs; founder runs only short Codespaces commands, always with the complete launch command at the end of instructions.


## 19 November — Blue/Mint reference-anchored expansion prepared

- **Violet complete (9/9), founder-approved.** All nine Violet combinations switch cleanly on the real device, including the final Cheeky/Satchel V2 shoulder fix.
- Added `tools/build_brim_colourways.py` on the feature branch. It reads the nine Violet WebPs already in Codespaces, plus the previously approved Blue/Mint Friendly/None and Friendly/Scarf references. It generates **14 additional candidates** (seven per colour), completing the 27 potential combinations without overwriting any of the 13 existing approved/reference assets.
- Technique: for each target, preserve *exact* approved Blue/Mint reference pixels wherever they correspond to unchanged pixels in Violet; derive only changed expression/accessory pixels using colour correspondences learned from both reference pairs. Warm leather, cream and tongue are protected. Enforces 512×512, aligned alpha, and no-overwrite safeguards; writes only after the entire batch has passed image checks.
- Local synthetic-image smoke test of the generator passed: 14 new assets, intact alpha, no changes to reference images, and clean refusal to run again over existing outputs. **This is NOT an on-device test of the user's actual Blue/Mint assets.** The script must validate the real assets in Codespaces, and any failed alignment check must be treated as a stop, not worked around blindly.
- Added `tools/test_build_brim_colourways.py` for mapping/alpha regression checks, and updated Avatar Lab to precache all 27 combinations when present. `main.dart` and Firebase remain untouched.
- **Next user steps:** `git pull --ff-only`; `python3 tools/test_build_brim_colourways.py`; `python3 tools/build_brim_colourways.py`; `flutter test test/brim_avatar*`; launch the isolated Brim Lab. Inspect Blue and Mint across all 9 expressions/accessories at hero and 48px, especially tongue, scarf edges, satchel strap, and dark-blue/yellow accent continuity.
- **Do not merge** or treat all 27 assets as approved until the founder's phone checks pass and the candidate files are deliberately committed/packaged. The historical Delightful assets and earlier ZIPs remain locally intact.


## 19 November — Complete 27/27 Brim visual set confirmed

- The founder installed Pillow in Codespaces, successfully generated the 14 missing Blue/Mint images and confirmed **all Blue and Mint expressions/accessories are present and visually look good** in the Avatar Lab. Violet 9/9 was already approved. **Brim 27/27 passes the founder's visual review** at the prototype level.
- The first Blue/Mint attempt had failed because Python Pillow (`PIL`) was missing; the resulting placeholders were missing files, not a failed artwork design. After installing Pillow and regenerating, the files loaded in the lab.
- **Critical next step: persist the 27 source WebP files and the local avatar asset declaration in `pubspec.yaml` to the feature branch.** The user has local untracked artwork in Codespaces and multiple historical ZIP/trial candidates. Stage exactly `brim_v1_{violet,blue,mint}_{gentle,playful,cheeky}_{none,scarf,satchel}.webp` (27 WebPs), not `delighted` trials or ZIPs, and inspect the staged diff before commit. The assistant cannot push these local binary files via its GitHub text editing connection.
- Do not merge this branch into `main` based on visual approval alone. After committing, check a clean checkout can build the isolated lab using tracked art, validate Flutter tests, and then address child-owned avatar saving, friend-safe identity display, parent card views, device recovery and privacy/security. Five additional distinct character designs remain an intended follow-up; first capture Brim's art pipeline and asset-size impact.


## 20 November — Brim V1 engineering handoff (awaiting clean-build execution)

- Founder approved all 27 combinations in Avatar Lab on the phone. GitHub has exactly 27 tracked WebPs (~5.91 MiB total), and `pubspec.yaml` registers `assets/avatar_prototype/`.
- Extracted `BrimArtPreview` into reusable `lib/avatar/brim_art_preview.dart`. The lab imports it without changing the approved instant switching, 220px hero or 48px face-focused portrait. No changes to production `main.dart`, Firestore or child saved identities.
- Added `tools/audit_brim_assets.py`: read-only 27-file Pillow decode, dimension, transparency, identical-alpha-per-accessory and duplicate checks. Local discarded Delighted trials are ignored.
- Added `test/brim_asset_inventory_test.dart`: verifies all 27 exact WebPs are present in Flutter's **asset bundle**, not merely on the filesystem. Existing selection/widget tests remain.
- Added `tools/verify_brim_clean_build.sh` for one-command verification from a **clean `git archive HEAD` snapshot**. It ignores untracked trials, checks the approved artwork, runs Flutter tests and builds the isolated web lab; does not deploy or modify the current checkout.
- Froze visual/asset engineering requirements in `docs/natter/BRIM_V1_SPEC.md`. The 27 files together decode to roughly 27 MiB of RGBA if all cached; the current lab preloads everything, which must **not** be copied blindly into a six-character production identity picker.
- **Next:** founder pulls branch and runs `bash tools/verify_brim_clean_build.sh` in Codespaces. Requires installed Pillow and Flutter. Report final pass or exact failure. A successful build completes Brim's **character-art + reusable-widget engineering gate**, not production profile persistence or cross-family security integration.
- After this handoff we will discuss the remaining five distinctive character designs and a sustainable multi-character rendering/palette/accessory workflow before adding full child-owned onboarding, profile, parent and friend visibility.


## 20 November — Brim V1 technical and visual sign-off COMPLETE

- Founder ran `bash tools/verify_brim_clean_build.sh` in Codespaces on `feature/child-avatar-identity`; screenshot explicitly showed `BRIM V1 CLEAN BUILD VERIFIED: 27 assets, tests, profile web build.` The script reported source commit `3604cb6`; no deployment or Firebase change was made.
- Founder also confirmed a final visual pass remained correct. **Brim V1 is closed as an approved 27-combination character-art and standalone reusable-component deliverable.**
- The committed source includes 27 WebPs, the asset registration, `BrimAvatarSelection`, the extracted `BrimArtPreview`, audited artwork and tests. Keep the no-crossfade switching and 48px face-biased crop.
- This does **not** mean Natter's end-to-end avatar identity feature is shipped: child-owned save/edit, onboarding/profile adoption, authorised parent views, friend-visible avatar-only projection, backward compatibility and recovery are separate release gates.
- **Next focus agreed:** discuss an efficient, consistent method for making the other five distinct avatar character types, comparing complete flattened artwork sets with carefully layered/parametric assets. Preserve Brim as the immutable visual quality reference; avoid replicating the lab's eager 27-image preload across six characters.
- No more Codespaces commands are needed for Brim itself. PR #18 remains draft until the broader identity and release checks are ready.


## 20 November — Zeev character production initiated (master approval pending)

- The founder supplied the original **six-character Natter concept sheet** and requested momentum rather than repeating Brim's many separate edit/test loops. Existing roster is Lumo, Brim, Pixl, Miri, Croft, Zeev; **Zeev is character two**.
- Zeev's concept: playful/energetic water-dragon, saturated blue body, ivory muzzle/belly, cyan glowing fin-like wings, ornamented swirling patterns, curling water-wave tail and gold accents. Do not substitute a second generic Brim dragon or unrelated creature.
- A standalone **Blue / Friendly / None** Zeev master image has been prepared as a 512×512 transparent WebP (`zeev_v1_blue_friendly_none.webp`, about 189 KB) with an original-concept comparison and 48px face-crop preview. This is a **candidate**, not founder-approved; PNG/ZIP review artifacts are conversation downloads, not committed to the GitHub feature branch.
- Two broad image-concept boards were generated for creative reference only. Their grids and any labels implying 27 approved Zeev assets are **not actual production artwork**. Only one full-size Zeev candidate exists so far.
- Key technical learning: Zeev faces to the viewer's left, whereas Brim's 48px avatar crop targets a face farther right. **Do not blindly reuse Brim's portrait alignment**; define a character-specific face focus while sharing the 512px image contract.
- Streamlined next steps: founder approves/revises a single isolated Zeev master; produce three distinct pixel-controlled expressions for the same body, then apply fixed scarf and satchel placements to those expressions; derive two alternate colourways from approved colour masters; package the 27-variant batch; conduct one automated inventory/silhouette QA and one focused phone-lab review before committing. No production `main.dart`, Firestore or child profile edits yet.


## 22 November — Zeev Blue expression trio accepted for accessory development

- The founder liked the Zeev Blue Playful (one-eye wink, animated grin, no tongue) and Cheeky (open-eyed grin, tongue out) candidates. They observed a minor difference in the side neck frills/spikes versus the Friendly master but explicitly considered it **not a deal-breaker**. Do not restart character design over this detail.
- The approved **Friendly master** remains the fixed primary reference. Playful and Cheeky are **visually accepted expression candidates**, pending same-canvas instant-switch QA and downstream accessory consistency checks; avoid describing them as fully engineering-verified assets prematurely.
- Converted the approved Friendly master and two expressions into the same 512×512 transparent WebP format and packaged a 3-file `Natter_Zeev_Blue_Expressions_Trial_Pack.zip` separately from GitHub. Filenames: `zeev_v1_blue_{friendly,playful,cheeky}_none.webp`. Review contact sheet: `Natter_Zeev_Blue_Expression_Trio_Review.png`. These binary review artifacts remain outside the repository until app testing.
- Priority now is **batch creation of Blue/Scarf and Blue/Satchel** for all three expressions, using attached/fitted accessory artwork and controlled compositing; check the upper strap and scarf-mouth overlap from Brim's earlier mistakes. Aim for a single nine-combination Blue review rather than repeated one-off aesthetic iterations.
- Zeev's profile face points viewer-left, unlike Brim: implement a character-specific 48px face crop when building the isolated selection lab, rather than reuse Brim's face alignment.
- After Blue's 9 are accepted, derive two colourways from the approved Blue sources, then integrate and test the full 27. Avoid editing production `main.dart` or Firebase during the artwork stage. Continue direct GitHub edits by assistant; short Codespaces commands for founder, with complete launch command last.


## 22 November — Zeev Blue nine-combination pack and isolated lab ready for on-device QA

- Prepared all nine **Blue** Zeev candidates in one trial ZIP: `Natter_Zeev_Blue_Nine_Trial_Pack.zip` (not in GitHub yet). Contains `assets/avatar_prototype/zeev_v1_blue_{friendly,playful,cheeky}_{none,scarf,satchel}.webp`, each 512×512 with transparency. The three no-accessory expressions are carried over from the previously reviewed Blue trio.
- The six new scarf/satchel candidates were made by applying a **single fitted scarf composite and a single strap/bag composite** onto each expression's existing 512×512 Blue artwork, rather than redrawing the dragon. Alterations are localised: scarf x≈102..259,y≈225..351; satchel x≈118..300,y≈242..406. All nine WebPs decode, preserve the original expression pose, and passed local affected-area checks. This is **artwork QA only**; founder has not yet approved the accessories on-device.
- The knitted purple scarf style comes from a separate creative render, extracted and fitted to Zeev's fixed body. The warm leather satchel uses a manually fitted shoulder strap and a small bag element adapted from Natter's established Brim accessory style.
- Saved a 3×3 review sheet `Natter_Zeev_Blue_Accessory_9_Review.jpg` and 48px face-crop preview; binary pack/review files are conversation downloads, not yet committed.
- Added `lib/avatar/zeev_lab_main.dart` as a **separate temporary, isolated Blue-only trial** (Natter theme, Friendly/Playful/Cheeky, None/Scarf/Satchel, hero and 48px previews, no crossfade or Firestore writes). Zeev's compact portrait uses a face-left alignment distinct from Brim. No production `main.dart` modification.
- Added `tools/install_zeev_blue_art.py`: checks exact nine ZIP entries, decodes 512×512 transparent WebP with Pillow, stages replacements safely and preserves other Brim/Zeev files. Existing `pubspec.yaml` already registers `assets/avatar_prototype/`. Added `test/zeev_avatar_lab_test.dart` for switching and asset-bundle tests; **not yet run in Codespaces**.
- **Next founder steps:** upload the full nine-image ZIP to Codespaces `assets/`, `git pull --ff-only`, run `python3 tools/install_zeev_blue_art.py assets/Natter_Zeev_Blue_Nine_Trial_Pack.zip`, `flutter test test/zeev_avatar_lab_test.dart`, and launch `flutter run --profile -t lib/avatar/zeev_lab_main.dart -d web-server --web-hostname 0.0.0.0 --web-port 8080`. Stop any other server on port 8080 first.
- **Acceptance:** switch all nine Blue combinations in the isolated lab; check scarf neckline and tassels, strap/bag placement, face expressions/48px legibility and no visible image jumping. Do not declare Zeev Blue complete or expand to two more colourways until that real-device review passes. User prefers short terminal commands and the full lab launch command last.


## 23 November — Codespaces allowance exhausted; alternate development route

- Founder reported 100% GitHub Codespaces usage for their personal account and expects the allowance to renew 1 December 2026. Do not ask them to open Codespaces or run terminal commands in the meantime.
- We can continue editing `feature/child-avatar-identity` directly through GitHub, with **independent GitHub Actions runner minutes** (public repository) for builds/tests, without using Codespaces.
- Added feature-only workflow `.github/workflows/avatar-branch-check.yml`: push-triggered for avatar code/tests/assets, runs approved Brim tests and compiles Zeev's isolated Flutter web entry point. The workflow uploads a web-build artifact but **does not publish Pages, touch main, alter Firebase or deploy the production app**. It cannot validate Zeev's nine asset-bundle tests until binary WebPs are committed to GitHub. Check the GitHub Actions run status separately before claiming success.
- A **single-file, completely offline interactive Zeev Blue review** (`Zeev_Blue_Offline_Avatar_Lab.html`) has been generated from the exact nine trial WebPs. It contains embedded images, Friendly/Playful/Cheeky and None/Scarf/Satchel controls, instant image switching, a face-focused 48px preview and all-nine thumbnails. No external requests or account writes. HTML is a conversation download; it is not the actual Flutter app and does not test Flutter performance.
- For phone-based review, download the HTML, open it from Android Files/Downloads in a browser (may require selecting an HTML viewer); if local HTML opening is blocked by the phone, fall back to the nine-image contact sheet or set up a separate isolated preview host. Do not alter the current Pages site, which deploys from `main`.
- Resume normal Flutter integration / on-device validation once Codespaces access returns, or optionally arrange separate preview hosting with appropriate isolation.


## 24 November — Zeev accessory regression corrected with approved V3 faces (awaiting review)

- User identified that the next set of Zeev Playful and Cheeky accessory renders reintroduced distorted/misaligned eyes. Root cause: **fresh whole-character redraws were used for accessories despite the previously accepted V3 face-only expressions**. Discard those accessory redraws as production candidates.
- Rebuilt Blue 3×3 artwork in an offline Python/Pillow process from the exact nine-source references: approved `Natter_Zeev_Blue_Face_Only_V3_Review.zip` (Friendly/Playful/Cheeky, None) plus the **existing Friendly scarf and satchel WebPs** in `Natter_Zeev_Blue_Nine_Trial_Pack.zip`. Confirmed the Friendly master in both source ZIPs is pixel-identical.
- Derived pixel-accurate accessory masks by comparing original Friendly/Scarf and Friendly/Satchel against Friendly/None. Scarf changes 12,511 pixels (bounds x=88..424,y=225..431); satchel changes 6,741 pixels (bounds x=88..354,y=242..406). Applied these exact changed pixels to each approved V3 base and **did not regenerate the dragon or composite new eyes**.
- Verified all nine final 512×512 lossless WebPs decode, preserve source alpha, preserve pixels outside the accessory masks, and preserve all approved face pixels above row 220. The 3 No-Accessory art files are unchanged at the visible-pixel level. The previously generated image-render outputs are for reference only; **not** adopted.
- Generated `Zeev_Blue_V3_9_Review.png`, `Zeev_Blue_V3_Offline_Review.html` (offline instant-switch phone review) and `Natter_Zeev_Blue_V3_Accessory_Repair_Pack.zip` (nine files). These are conversation artifacts, not yet committed to GitHub or verified in Flutter. Do not replace the existing approved candidate assets until founder has assessed the visual results.
- **Next:** founder checks all nine with offline preview, focusing on eyes, scarf chest overlap, satchel strap placement and 48px portrait. Upon visual approval, commit nine reviewed WebPs and use GitHub Actions for no-Codespaces Flutter verification. Avoid further whole-body regeneration for avatar expressions/accessories.


## 25 November — Separate public GitHub Pages Zeev preview prepared (hosting setup pending)

- User's Android Files app displayed the downloaded offline HTML as raw text, not an interactive page. Agreed to use a normal HTTPS link via a **separate public GitHub Pages repository**, keeping the existing Natter Pages deployment and `main` branch untouched.
- Confirmed `leetreays/Natter` already deploys the app to its Pages site from `main`. GitHub supports **one Pages site per repository**; changing that repository's publishing source could replace the live app. **Do not repurpose Natter's Pages deployment for preview.**
- Prepared single-file Pages-ready `index.html` (~4.4 MiB, self-contained 9 V3 WebP data URLs) and optional `Natter_Avatar_Preview_GitHub_Pages.zip` as conversation artifacts. Verified embedded WebP bytes match **all nine** `Natter_Zeev_Blue_V3_Accessory_Repair_Pack.zip` images exactly and there are no external image/network dependencies. Includes instant switches and 48px portrait preview.
- The GitHub connector can create files in existing repositories but **cannot create a new repository or configure GitHub Pages**; user needs to create a public repository named `natter-avatar-lab`, upload the supplied `index.html` to its main root, then choose Settings → Pages → Deploy from branch → main → /(root) → Save. Once published, expected URL is `https://leetreays.github.io/natter-avatar-lab/`; **not verified live until user completes setup**. GitHub Pages is public, no child data is included.
- The new Pages repo may need installation access granted to the connected GitHub app before direct programmatic future edits. Until then, avoid claiming automatic preview publishing. No Codespaces usage required.
