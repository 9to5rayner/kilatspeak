# KilatSpeak — Development Progress

## App identity
- Name: KilatSpeak
- Package: com.kilattech.kilatspeak
- Stack: Flutter, Firebase (RTDB + Auth), kie.ai (Gemini 3.5 Flash STT/translate, ElevenLabs TTS via kie.ai)
- State management: Riverpod (planned, Phase 2)
- Routing: go_router (planned, Phase 2)

## Phase 1 — DONE
- flutter create with org com.kilattech, project kilatspeak
- Folder structure: lib/models, services, screens, widgets, theme, providers (with .gitkeep placeholders)
- Fixed disk space issue (C: drive) that broke first NDK download
- Fixed android/app/build.gradle.kts: removed deprecated kotlinOptions block,
  migrated to `kotlin { compilerOptions { jvmTarget.set(...) } }` syntax (AGP 9.0 compatibility)
- Confirmed build + deploy to physical Samsung Tab S7 FE (SM-T733, Android 14)
- Known non-blocking warning: project uses older Kotlin Gradle Plugin application method;
  Flutter recommends migrating to "Built-in Kotlin" eventually — deferred, not urgent
- Git repo initialized, pushed to https://github.com/9to5rayner/kilatspeak

## Environment notes
- Git needed: `git config --global --add safe.directory <path>` for each new project folder on this machine
  (or use `git config --global --add safe.directory *` to trust all folders)
- Git identity configured: user.name / user.email set globally

## Next: Phase 2 — Theme, routing, Riverpod skeleton