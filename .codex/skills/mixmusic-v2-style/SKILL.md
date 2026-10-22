---
name: mixmusic-v2-style
description: Implement or refactor MixMusic v2 Dart/Flutter code in the owner's concise, direct style. Use for new architecture, models, services, Lemon JS plugin logic, playback, pages, and state code in this repository; do not preserve legacy state management, UI, audio, framework wrappers, or lyric implementation merely for compatibility.
---

# MixMusic v2 Style

Write code the owner can understand at a glance. Prefer the shortest clear path from input to result. The early version is for validating the main flow, not pre-solving every future failure.

## Preserve the right things

Preserve from the current project:

- The direct, readable coding style.
- Small models with public fields and simple constructors.
- Straightforward method calls and data flow.
- `pluginId/package + dynamic id` as the external resource identity.
- The existing plugin business idea: plugins provide sources, the host invokes a unified contract, and failed playback may match another source.

Do not preserve merely because it exists:

- Current state management.
- Current page implementation or UI component libraries. Preserve the existing visual style and layout habits; replace their implementation with Lemon UI.
- Current routing.
- Current audio system.
- Current framework wrappers.
- Current lyric implementation.
- Current database implementation.
- Accidental inconsistencies or known bugs in legacy code.

The legacy project was written without AI assistance and evolved over time. Treat mixed libraries and inconsistent patterns as historical implementation details, not as the owner's intended style.

## Default implementation style

- After moving or deleting files, promptly remove the resulting empty source directories. Verify they are empty and keep cleanup within the task's scope.
- Preserve the owner's existing code organization: directory grouping, file naming, and where related models, page state, services, and widgets live. Inspect the archived v1 structure before adding feature files.
- Adapt that organization to the new libraries without introducing a new architectural layering scheme. If a concrete feature needs an organizational change, explain the reason and proposed change to the owner first.
- Prefer one concrete class and one obvious call path over several abstraction layers.
- Keep methods short and name them after the action: `searchSong`, `loadMore`, `play`, `favorite`, `download`.
- Use ordinary variables and direct returns. Avoid patterns whose main purpose is architectural ceremony.
- Keep related logic together until real reuse or complexity proves it should move.
- Prefer simple constructors and explicit fields over builders, factories, adapters, mappers, and DTO/domain duplication.
- Use the framework or library API directly when a wrapper adds no meaningful simplification.
- Keep async flows linear with `async`/`await` unless a stream is genuinely required.
- Let the state be easy to see. Do not scatter one feature's state across many coordinators, notifiers, use cases, and repositories.
- Write comments only for non-obvious business rules, plugin protocol constraints, or temporary decisions. Do not narrate normal Dart code.
- Use Chinese user-facing text where the product uses Chinese. Use concise English identifiers in code.
- Run the formatter, but do not mechanically rewrite unrelated legacy files.

## Simplicity rules for the early stage

Build the successful main path first.

- Do not add speculative fallbacks, retries, caches, compatibility shims, circuit breakers, or recovery states.
- Do not add repeated null checks for values guaranteed by the current contract.
- Do not wrap every call in `try/catch`.
- Do not create custom error hierarchies before the UI or protocol needs them.
- Do not introduce `Result`, `Either`, command buses, event buses, service locators, or generic repository layers by default.
- Do not add configuration points for behavior that has only one current implementation.
- Do not design for hypothetical plugin types while implementing a concrete source-plugin flow.
- Do not optimize or deduplicate code before the repeated shape is stable.

Add validation immediately only at a real boundary where bad data would obscure the main flow or corrupt stored state, such as plugin JSON decoding, database writes, or native resource ownership. Keep that validation local and small.

When a requirement is explicitly about security, persistence, concurrency, or destructive behavior, implement the necessary correctness without turning surrounding code into a generalized framework.

## Models

Favor plain models similar in spirit to the current entities:

```dart
class Song {
  String pluginId;
  dynamic id;
  String title;
  List<Artist> artists;
  String? cover;

  Song({
    required this.pluginId,
    required this.id,
    required this.title,
    this.artists = const [],
    this.cover,
  });
}
```

- Keep the plugin's `id` opaque and dynamically serializable.
- Do not add a resource `type` to identity; separate interfaces and tables already provide the type context.
- Database-local IDs may exist for relational storage, but they must not replace or mutate the plugin ID.
- Avoid `copyWith`, equality frameworks, sealed hierarchies, and generated boilerplate until a concrete feature needs them.

## Functions and services

Prefer direct orchestration:

```dart
Future<void> play(Song song) async {
  var source = await plugins[song.pluginId]!.play(song);
  await player.open(source.url);
}
```

Do not expand this early flow into multiple use cases, resolvers, strategies, policies, and result wrappers. Introduce one of those only when at least two real implementations or a demonstrated complexity require it.

For plugin APIs, keep one visible method per business operation and map it directly to the Lemon JS contract. Reuse the current plugin logic concept, but redesign the runtime and interface cleanly for Lemon JS.

For playback, use the prepared MPV wrapper as the real engine and adapt it to the required `lemon_audio` `LemonAudioPlayer` interface. Let `lemon_audio` own system media integration; keep queue, source resolution, fallback matching, and music-domain state in MixMusic. Do not call `audio_service`, `audio_session`, or platform media APIs directly from feature code.

Use the local `lemon_lyric` project for the v2 lyric system. Its normal, word-level, and translated lyric capabilities already exist; do not rewrite those data features. The current issue is jank in the intended Apple Music-style rendering, scrolling, highlighting, blur, layout, and animation. Optimize update scope and rendering while preserving that visual direction. Avoid rebuilding the whole lyric page on playback ticks, reuse parsed lyrics, and allow expensive effects to be temporarily simplified until the view is smooth on Android, Windows, and vehicle layouts.

For local persistence, prefer a relational database with direct, readable queries, transactions, bulk replacement, and migrations. The database library is intentionally undecided. Do not introduce a generated DAO/repository hierarchy before the real history, favorite, playlist, download, and source-mapping queries are implemented.

## State and UI

The v2 state system and UI are new. Do not imitate GetX or the old Material/Fluent split just to resemble legacy code.

- Use `go_router` as the only application routing system.
- Use the owner's `lemon_x` as the state-management system.
- Use the owner's `lemon_ui` as the unified UI system for phone, tablet, desktop, and vehicle layouts.
- Use `lemon_ui` for UI components wherever possible. Do not build replacement or reusable UI components in MixMusic. When a required component is missing, tell the owner what is needed so it can be added to `lemon_ui`; compose pages from available components and Flutter layout primitives.
- The owner plans to extend `lemon_ui` to plugin UI later. Keep host and plugin UI aligned with that shared component and visual system; add the plugin-side integration when it becomes available.
- Do not introduce GetX, Navigator-based parallel routing, or another state-management library.
- Use `lemon_x` directly and simply. Do not hide it behind compatibility wrappers or recreate GetX concepts on top of it.
- Preserve the existing overall page style, visual character, and familiar layout. The v2 rewrite primarily replaces UI components with `lemon_ui`; do not redesign the visual direction unless the owner requests it.
- Use the archived v1 pages as visual references. Unify accidental phone/desktop inconsistencies while retaining their shared design language.

- Keep feature state close to its page or feature controller.
- Expose only the values and actions the UI uses.
- Prefer a small number of meaningful states over many booleans and defensive branches.
- Build one readable widget tree; extract a widget when it has a clear name, reuse, or makes the parent substantially easier to read.
- Do not create `BasePage`, `BaseController`, generic screen factories, or large design-system abstractions during initial feature work.
- Keep phone and desktop behavior shared where practical, with small layout branches instead of duplicated feature implementations.
- Layout rules: phone and portrait tablet use the vertical phone layout; landscape tablet shows a player beside the phone layout; desktop uses horizontal sidebar/content layout. Resolve device type with `lemon_ui`, not window width alone.
- Share page structure, feature state, and business components across platforms. Use responsive `lemon_ui` layouts for genuine screen-size differences instead of maintaining separate mobile and desktop feature pages.
- Treat Android, Windows, and vehicle layouts as the first release and validation targets. Keep shared code portable for later iOS, macOS, Linux, and Web support; consider OpenHarmony last. Concentrate platform differences in platform setup, system adapters, and responsive layout rather than feature logic.

Follow `lemon_x` idiomatically, using its simplest form first.

## Plugin logic

- Never put plugin implementations, plugin demos, platform endpoints, or platform-specific validation code into MixMusic or commit them here. Keep them in the separate plugin repository. Small synthetic in-memory fixtures for host unit tests are allowed.
This is the principal legacy concept to retain.

- The host owns unified pages and core playback behavior.
- Plugins provide source-specific data and operations.
- Login flow belongs to the plugin; the host only exposes required UI/native primitives and secure storage.
- External resource identity remains `pluginId + dynamic id`.
- A favorite keeps its original source. Match another source only when playback fails or the user explicitly asks.
- Favorite targets are current platform, local MixMusic library, or both. Use the global default for a normal tap, open target selection on long press or when no default is set, and treat the current platform as the initial default unless this decision changes.
- Keep Lemon JS method names and payloads obvious and close to the domain operation.
- Avoid a universal capability framework until more than the source-plugin flow is actually implemented.
- Treat `lemon_js_extensions` as the purpose-built and required plugin foundation for MixMusic v2, not as an optional candidate. Use it for manifest, installation, Session, service, JSUI route, flow, storage, and lifecycle infrastructure. Do not rebuild or replace those facilities inside MixMusic.
- Keep music API business methods close to the legacy API where their meaning is still valid, while freely fixing names and parameters that were constrained by the old runtime.
- Expose typed Dart music methods to pages, state, and playback code. Keep string export dispatch inside the Lemon JS contract adapter; do not scatter method-name strings through business code.
- Prefer manifest-based mixed packages for normal installation. If bare single-file JS import is later supported, adapt it into the same package model instead of maintaining a parallel runtime path.

## Working sequence

### Dependency modification authority

- Treat `mpv_audio_kit`, the third-party audio dependency, as read-only. Do not modify its repository or cached source.
- The owner's other libraries may be modified, but notify the owner before every modification, naming the library, the issue, and the intended change. Never silently modify sibling repositories or dependency sources.
- This permission does not authorize creating missing UI components inside MixMusic; report missing `lemon_ui` components to the owner as previously agreed.

For each feature:

1. Identify the shortest end-to-end user flow.
2. Implement the model, one state owner, the plugin/service call, and the UI needed for that flow.
3. Verify the successful path.
4. Add only the error handling needed to understand failures during development.
5. Defer hardening, extensive edge cases, compatibility, and optimization unless the user asks for them now.

Before finishing, remove unused abstractions, redundant guards, placeholder extension points, and comments that merely explain syntax.
