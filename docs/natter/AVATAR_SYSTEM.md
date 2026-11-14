# Natter — Child Avatar Identity (V1 draft)

**Status:** Design discovery; awaiting visual direction and approval.  
**Branch:** `feature/child-avatar-identity`  
**Started:** 11 November 2026

## Product intent

A child should feel that their Natter identity is theirs. Avatar creation is a moment of self-expression introduced early in the experience, near the child's promises, rather than a reward, streak, score or retention mechanic.

## Known product requirements

- A child chooses or creates an avatar early in onboarding, with a sensible default for existing accounts and interrupted onboarding.
- The same identity appears on the child's Chats/profile surfaces, approved friends' conversation identity circles, and the linked parent's **Your family** card.
- The child can edit their avatar later without unlocking parts through messaging, engagement, purchases, or behavioral assessments.
- The avatar must be inclusive, recognisable at mobile small sizes, visually consistent with Natter's premium navy/night-sky design, and not require photos.
- Existing children, friendships, parent cards, device relinks and message history must continue to work.

## Current implementation findings (inspect against main before coding)

- `AvatarData`, `AvatarPreview` and a legacy `AvatarBuilderScreen` exist in `lib/main.dart`, but the builder uses emoji-style components; the `AppState.avatar` value is in memory and is not an authoritative shared identity.
- The persisted `parents/{parentId}/children/{childId}.avatar` value and child device session currently use a short icon ID such as `owl`. Parent family cards use this string to choose a generic icon.
- `NatterChildChatTile` already exposes an optional `avatar` widget slot; without it, the tile shows the friend's initial.
- The current child profile deliberately does not surface the legacy avatar builder.
- Firestore child documents are private to the linked child/parent under present rules. Approved friends must **not** gain broad read access to them merely to see avatars.

## Provisional creative direction — 11 November 2026

**Direction under exploration:** Primarily **B — imaginative/fantasy creatures**, with the possibility of selected elements from **C** (broader character choices). This is a design hypothesis, not a locked art direction.

The user emphasised that the creation process itself should encourage healthy online habits. The avatar should make digital identity more thoughtful **without** becoming a reward, behavioural score, obligation to log in, or judgement of a child's personality.

### Proposed child experience

1. **Choose who represents you:** pick an imaginative creature/character, then personalise its look. Avoid requiring a physical likeness, personal photo or gendered choices.
2. **Understand visibility:** show a simple, accurate preview of the avatar as it will appear to the child, approved friends and linked grown-up, with concise privacy explanation.
3. **Connect to promises:** use one short, non-judgemental reflection such as “Your character is how friends recognise you. What matters most is how you treat them.” Link naturally with the existing promise/rite flow, rather than adding a quiz or mandatory long lesson.
4. **Save and own it:** child confirms their choice; reassure them it can be changed later without needing to earn anything.

### Guardrails

- **Appearance never indicates 'good' or 'bad' behaviour.** No character sadness, damage, lost accessories or public moral badges in response to messages or mistakes.
- No rewards tied to messaging frequency, read receipts, streaks or time spent in-app; no pet-care or daily check-in mechanics.
- No assignment of 'kind', 'brave', 'troublemaker' or other personality traits based on creature choice.
- Kindness guidance remains in the conversation at the appropriate moment, rather than being personified as a character that watches or judges the child.
- Use a small set of high-quality, inclusive, customisable characters that remain legible as 48px identity portraits and feel coherent with Natter's premium design.
- Distinguish the **child's identity avatar** from existing friendship celebration mascots and Natter brand artwork.

### Open visual decisions

- Whimsical animals versus entirely invented creatures (or a cohesive mixture).
- Expressiveness: minimal 2D illustrations versus richer dimensional styling, while remaining readable at small sizes.
- Avatar builder depth: curated templates with a few meaningful choices versus many individual components.
- Precise placement alongside the existing promises and sealing ceremony.

## Recommended V1 prototype — 12 November 2026

**Creative proposal (not yet final artwork):** Start with **five or six original Natter creatures**, each with a distinct, easy-to-recognise silhouette at 48px, but some familiar animal-like warmth (ears, tails, whiskers, wings). Use a common illustration language rather than separately styled stock emoji. This resolves the B-versus-C tension by giving the child imaginative freedom without asking them to reproduce a real-world identity.

**Suggested first customisation set:** creature shape; a curated body colour; one pattern/detail; one optional accessory; and a gentle expression choice. No labels assigning moral values, gender, abilities or personality to shapes. All options available from the start, and all reversible.

**Intended rite sequence:** child name → choose and customise creature → short “who can see me?” preview → existing promises/seal → welcome. For existing children, offer an optional character-creation entry from Profile, without blocking their chats.

**Short educational message (draft copy):**
> “This character helps your friends recognise you. Behind every character is a real person. Your words matter more than how your character looks.”

The message is a one-off gentle reflection, not a question with right/wrong answers or a repeated tutorial. The privacy preview must describe *actual implemented access*, not aspirational visibility before the necessary friend-safe projection and rules are complete.

**Proposed implementation checkpoints:**
1. Review six cohesive character concepts at large and chat-list scale; verify appeal, readability and contrast on navy before coding.
2. Add a standalone deterministic avatar renderer/configuration model and a local builder behind the feature branch.
3. Add safe child-owned persistence and editability, with legacy icon fallbacks and device-relink coverage.
4. Add the approved-friend avatar-only projection and parent-card integration; security-test access.
5. Integrate onboarding and test across child, friend and parent accounts before merging.

**Success criteria:** Children can create an identity without disclosing personal appearance, understand who sees it, change it without rewards or loss, and see the same character consistently across the authorised experiences. No new engagement loops or behaviour-driven avatar changes.

## Questions for design decision

1. Visual language: illustrated human characters, fictional creatures/mascots, or a hybrid choice?
2. Customisation depth: starting templates vs individually chosen face, hair, clothes and accessories?
3. Onboarding moment: before promises, between promise-selection and sealing, or after the rite?
4. Later edits: always available from Profile; no reward locks. Consider a clear edit/save/revert flow.

No choice above is final without review.

## Feasibility and quality gate — 12 November 2026

**Founder concern:** The concept illustrations have polished painterly/3D lighting. Simply placing flat transparent PNG accessories over a finished creature image will create cheap-looking attachments with incorrect occlusion, contours, shadows and highlights. Avoid committing to six fully customisable creatures before proving an art/rigging pipeline.

**Technical distinction:** Finished generated concept images are *references*, not animation-ready, layered, edit-ready character files. A clean Flutter `Stack` is insufficient to recreate the illustration quality. Modular artwork can avoid a separate exported image for every combination, but each creature/accessory combination still needs carefully designed geometry, front/back layers, masking, lighting and edge work; a common asset rarely fits every silhouette.

**Possible production approaches:**
- **Curated complete variants:** each chosen look is finished and art-directed as a whole. Highest consistency and minimal runtime complexity, but fewer choices and higher asset count.
- **Professionally layered/rigged 2D:** per-creature modular source artwork with specific anchor points, masking, shadows and accessory variants; potentially Rive or equivalent for Flutter integration. Fewer complete renders, but significant illustrator/rigging effort and 3D-painterly look may be difficult to reproduce from vectors.
- **Hybrid:** finished creature variants for major silhouette changes plus a *small* number of creature-specific, fitted, high-quality modular customisations; colour options where artwork supports clean recolouring. Potential compromise.

**Required proof before scaling:** one creature only, original source art with editable layers, two fitted accessories (one should cross in front of and behind the body, such as a scarf), two palettes and one expression change; demonstrate in Flutter at both hero and 48px chat-tile sizes. Inspect edge quality, shading, perspective, clipping, reload/persistence and web performance. If the result is visibly inferior to the original concept, *stop* and reconsider the product scope instead of multiplying assets across six characters.

No application work on six-creature customisation, bulk asset production, backend sharing or onboarding integration until this quality gate has been reviewed. No claim that static AI-generated character concepts already constitute editable production assets.

## Development checkpoint — 13 November 2026

The founder has accepted the Brim Avatar Creator layout direction and asked that we **stop refining illustrative mockups**; actual Flutter UI must reuse the established `NatterChildBackground`, `NatterChildTheme`, `NatterChildSurface`, navigation and brand button palette in `main.dart`.

The isolated `lib/avatar/brim_avatar_selection.dart` selection model and `test/brim_avatar_selection_test.dart` are now committed on the feature branch; they describe three colourways, two expressions and three accessory choices, with stable choices, safe fallbacks and no Firebase or app-screen integration. Tests must still be run in Codespaces.

**Next gate (real artwork, not more boards):** Produce an isolated, transparent, common-canvas Brim master with a genuinely fitted scarf demonstration. The Brim concept board PNGs are flattened compositions and **must not** be mistaken for detachable accessories or production-ready sprites. Check the unchanged body/pose geometry, clean edges, correct front/back occlusion, coordinated lighting/shading and the hero-versus-48px portrait before scaling the system. Prefer one fully finished scarf/no-scarf comparison and one palette change initially; if professional layered source artwork is unavailable, use deliberately curated *complete* character variants instead of fake overlays.

**Then:** Add a feature-branch-only Flutter Avatar Creator using the existing Natter child components, fast asset swapping, and a 48px preview. Keep first-run onboarding, Firestore, parent/friend sharing and main-branch deployment untouched until the quality gate passes.

## First real Flutter artwork review — 13 November 2026

The founder uploaded live Codespaces screenshots of the isolated Brim Lab on port 8080 after installing the two violet/gentle candidate complete WebP renders (None and Scarf).

### What is now supported by actual app evidence

- The child theme and interaction controls render correctly on a mobile screen.
- `Violet + Gentle + None` and `Violet + Gentle + Scarf` each resolve to a real complete Brim illustration.
- The scarf illustration visibly integrates around the neck with plausible folds, occlusion and shading, rather than being drawn as a generic top-level overlay.
- Character identity and overall composition are convincingly similar for this demonstration. This is an **initial curated-variant art pass**, not a production asset sign-off or proof that automatic accessory layering works.
- The chat-preview image rendered but the original full-body fit made Brim too small to read comfortably at 48px. A feature-branch refinement now crops/scales the same illustration into a face-oriented circular portrait. It **needs a fresh visual check**.
- The initial prototype status text incorrectly implied that no artwork existed; feature-branch text now accurately refers to two test illustrations and placeholders for other combinations.

### Remaining feasibility gaps / no-go until addressed

1. Confirm the cropped 48px portrait is recognisable and well-framed in both scarf/no-scarf variants, including edge halos, clipping and readability.
2. Test the art swapping experience in-person for jank/flicker and visual continuity; screenshots alone cannot verify smoothness.
3. We have only **2 finished combinations of 18** for Brim. The hybrid selection model does not avoid the need to create/verify additional complete variants or invest in professionally fitted layer source art. **Do not treat this trial as evidence that 18 variants × six creatures (108 complete renders) can be generated consistently or affordably**.
4. Test a **second colourway** in the same pose and ideally one changed expression to evaluate whether the image-production process scales without geometry drift.
5. Finish full test suite and release-profile build before any merge. No Firebase/auth or production profile integration yet.
6. Review candidate licence, transparency/edge cleanup and accessibility for the eventual production pipeline.

**Current verdict:** A credible proof of *curated complete-artwork switching* with integrated visual styling; the broader reusable hybrid system remains unproven. Scope further work to visual quality/production-pipeline gates rather than multiplying variants prematurely.

## Chat-icon visual gate — accepted for the feasibility lab (13 November 2026)

The founder supplied phone screenshots of both complete-artwork variants (Violet/Gentle/None and Violet/Gentle/Scarf) after reducing the face crop to 1.55×. The face is now recognisable, adequately framed and the scarf is still legible in the circular 48px preview. **Accept the current crop for the lab; do not keep making micro-adjustments.** The first-switch flicker was separately reported resolved after preloading and gapless playback.

**This is a *visual and interaction pass for two curated full-image variants*, not proof that modular layering, generated variants, or all other avatar combinations will work.** No artwork is yet committed in PR #18; two review assets remain local to Codespaces. Full eight-test suite, profile build, and actual asset packaging remain outstanding.

### Next decisive feasibility experiment: second colourway

- Start from the *same* Violet/Gentle/None and Violet/Gentle/Scarf master art. Prefer selective body/wing recolouring with preserved shading and exact outlines over independently redrawing Brim with generative image tools.
- Produce Blue/Gentle/None and Blue/Gentle/Scarf as two matched, transparent, same-canvas candidates with equal pose, proportions and scarf occlusion. Do not apply a flat tint to every pixel, including the cream belly, horns, eyes and scarf.
- Check that alternating Violet ↔ Blue on mobile feels continuous: the body, snout, wings, horns, eyes, tail and overall scale must not jump or morph. Verify 48px portrait and first-switch performance.
- If colour variations cannot be art-directed consistently without expensive manual re-rendering, narrow V1 customisation rather than manufacturing dozens of low-quality variants.
- Keep the portrait accepted and the live child app untouched; continue on feature branch in draft PR #18.

## Blue colourway failure and controlled-colour correction — 14 November 2026

**Real-device verdict on the independently generated Blue pair: FAIL (not suitable for production).** The founder reported visible shape/size shifts between Violet and Blue and **between Blue/None and Blue/Scarf**, plus inconsistent Blue hue. Screenshots unnecessary; this failed the previously defined visual continuity criteria. Do not repeat independent generated redraws for supposedly identical avatar customisations.

**Corrective experiment:** Recolour existing accepted Violet/Gentle/None and Violet/Gentle/Scarf source images directly in pixel space, changing only selected purple/blue material colours while preserving each source image's original RGBA alpha mask, 512×512 canvas, bounding box, and per-pixel coordinate grid. Preserve cream horns, belly plates and claws as far as practicable, and preserve existing scarf construction; use the **same recolouring parameters** on both accessory variants.

A replacement Blue review pack, `Natter_Brim_Blue_Pixel_Locked_Test_Pack.zip`, has been produced separately. Automated image comparisons confirmed the output for **each matching Violet → Blue accessory state** has identical canvas dimensions, alpha mask and bounding box; the ZIP was integrity checked. This proves no geometric drift *across colour switch*. It **does not** remove any subtle framing differences already present in the two original Violet/None and Violet/Scarf master images, nor guarantee perfect art direction along mixed-material colour boundaries.

**Retest:** Install the replacement pack in the local Brim Lab, overriding the earlier Blue candidates, then compare Violet ↔ Blue at fixed accessory (None and Scarf), Blue/None ↔ Blue/Scarf, the 48px portrait and first-switch smoothness. Look specifically for colour spill at the cream/pink-to-blue transitions, horns and scarf trim. Reject if quality feels patchy or if accessory changes still jump. Do not merge PR #18 or expand the variant matrix until this is accepted.

**Production implication:** Pixel-locked recolouring is promising for *palette changes* from a single approved pose; it does not solve the hard problems of adding new expressions, wings, body markings or accessories from flattened illustrations. A professional modular art pipeline or restrained set of curated complete appearances is still needed to scale.

## Proposed implementation sequence (after direction is approved)

1. Define a compact, versioned avatar configuration with reliable defaults and backwards-compatible migration from the legacy icon strings.
2. Build reusable, deterministic Flutter rendering at small and large sizes (chat tile, child identity, parent family card).
3. Provide child-owned builder, first-run placement and later Profile edit entry point; avoid accidental changes until Save.
4. Persist the canonical avatar configuration under the child's own record with appropriate write permissions. Ensure device recovery and another authenticated session restore it.
5. Make an **avatar-only, least-privilege projection** available to approved friends through an authorised path; do not expose child profile fields or messages.
6. Verify live updates across parent/child/approved-friend devices, unapproved access denial, deletion/relink behavior and fallbacks.
7. Flutter tests, Firestore emulator rules tests where rules are modified, web profile build and staged manual visual review before merge.

## Not in V1

Photo uploads, public browsing or search, avatar marketplaces, earned/unlocked items, spending, behavioural scores, visible engagement counters, AI-generated likenesses or unrestricted user-uploaded artwork.

## Adjacent work

Offline/pending message status is separately tracked in [Issue #17](https://github.com/leetreays/Natter/issues/17) and the active roadmap, queued after the avatar project. This work must not be forgotten or folded into avatar scope.
