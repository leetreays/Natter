# Brim V1 — approved character and engineering specification

**State (20 November 2026):** All 27 combinations have passed the founder's
on-phone visual review. Artwork and the isolated lab are committed to
`feature/child-avatar-identity`. Build/asset-regression checks and delivery
performance are separate validation gates; the child identity feature is **not
yet connected to Firestore or production onboarding**.

## Identity and visual contract

Brim is one of six planned original fantasy-creature identities for Natter.
The child should be able to choose appearance without earning or unlocking it.
Avatar appearance must never imply good/bad behaviour, popularity or safety.

| Dimension | Supported choices |
| --- | --- |
| Colour | Violet, Blue, Mint |
| Expression | Friendly, Playful, Cheeky |
| Accessory | None, Scarf, Satchel |
| Combinations | **27**, all approved in isolated Avatar Lab |

- Friendly: warm open-eyed smile.
- Playful: clearly visible wink; no tongue.
- Cheeky: open-eyed mischievous grin with a small pink tongue.
- Existing colour identities are frozen: distinct Blue, and Mint with darker
  blue/yellow accents; accessories use fitted scarf and warm leather satchel.
- Do not redraw the entire body to create an expression/accessory/colour.
  Preserve the original character's proportions, mask, pose and transparency.
- At 48px, prioritise a recognisable face over showing the full accessory.
  The established crop is intentional. Switching is instantaneous: **no crossfade**.

## Asset contract

Committed directory: `assets/avatar_prototype/`.

All 27 files must be 512 × 512 WebP images with transparency, following:

```
brim_v1_<colour>_<expression>_<accessory>.webp
```

Internal identifier `gentle` **means the visible Friendly option**. Keep it
for asset and legacy serialization compatibility; do not rename files in
isolation. `delighted` was an abandoned experiment, not a selectable V1
expression. Legacy serialized `delighted` resolves safely to Friendly.

The existing `BrimAvatarSelection` produces stable deterministic asset keys.
`BrimArtPreview` is exported from `lib/avatar/brim_art_preview.dart` for
reuse in future child-facing screens. The isolated prototype screen lives in
`lib/avatar/brim_lab_main.dart`; it does not persist choices.

**Do not publish the old trial ZIPs** or discarded Delighted assets as part of
the V1 production set. Source editable artwork is limited: these are complete
raster renders plus developer-side recolour/compositing tools, **not** a
general-purpose skeletal rig.

## Source and repeatability

The nine Violet assets are the approved master set.
The Blue and Mint Friendly/None and Friendly/Scarf assets serve as the colour
references. `tools/build_brim_colourways.py` transfers reference colours
onto the remaining expression/accessory images, preserving matching pixels
and alpha. It deliberately refuses to overwrite existing output files.

The builder is a **developer-only** tool, not a Flutter app dependency:
requires Pillow (`python3 -m pip install Pillow`). Re-running it on a
complete, committed 27-image directory should refuse to overwrite generated
assets. Do not delete approved versions merely to make regeneration succeed.

## Verification before treating Brim as implementation-ready

1. `python3 tools/audit_brim_assets.py` — decodes 27 WebPs using Pillow,
   checks 512×512 dimensions, transparency and pixel-locked alpha across
   all colours/expressions for each accessory.
2. `flutter test test/brim_avatar*` — tests selection and UI interaction.
3. `flutter test test/brim_asset_inventory_test.dart` — verifies that
   Flutter's compiled asset bundle contains all 27 exact, valid WebP files.
4. `flutter build web --profile -t lib/avatar/brim_lab_main.dart` — tests a
   production-like build of the isolated entry point; does **not** deploy.
5. Open the isolated lab on a phone and confirm selection, 48px readability,
   no image jumps and acceptable loading behaviour.

Previous on-device review passed all 27 visual choices. The new
build/asset-audit checks must still be run in Codespaces before marking the
engineering handoff passed.

## Runtime budget and scaling warning

The 27 committed WebPs total approximately **5.91 MiB compressed**.
At 512 × 512, each RGBA image can occupy approximately **1 MiB decoded**;
caching all 27 simultaneously is approximately **27 MiB** before cache and
UI overhead. The isolated lab precaches all candidates for convenient
switching; **this is not an approved production-loading strategy**.

Five more equally sized creatures would imply up to 162 image variants,
roughly 35 MiB compressed and 162 MiB if simultaneously decoded, before
normal app assets and other overhead. Actual figures will depend on artwork,
compression and the chosen cache policy. Do not eagerly cache the complete
catalogue in production. Plan selective/lazy loading, profile portrait
thumbnails and measured phone/web start-up times before rollout.

## Boundary for the next phase

Brim is a **finished character art set**, not yet a complete shipped child
identity feature. Before actual rollout we still need:

- choose the remaining five creatures and decide shared customisation rules;
- generic avatar selection model / renderer across multiple characters;
- child-owned save/edit and onboarding/Profile entry points;
- authorised parent view and friend-safe avatar-only projection (do not
  grant friends broad access to private child documents);
- migration/fallback from existing icon IDs and tests for device recovery;
- testing of performance, build, and identity visibility across roles.

Avoid premature merges or public exposure of avatar identity data before
those cross-role security rules and flows have been tested.
