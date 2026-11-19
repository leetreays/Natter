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
