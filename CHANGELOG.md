# Changelog

## [0.1.3] - 2026-03-22

### Changed
- Add runtime dependencies: legion-cache, legion-crypt, legion-data, legion-json, legion-logging, legion-settings, legion-transport
- Replace Legion::Logging stub in spec_helper with real sub-gem requires
- Add Helpers::Lex stub to spec_helper for standalone spec runs
- Update auto_fix_spec to use hide_const for Legion::Data::Local unavailability contexts

## [0.1.2] - 2026-03-20

### Added
- `codegen_fixes` table migration for self-healing pipeline tracking
- `Runners::AutoFix` for LLM-powered automated extension repair with git branch creation and spec validation
- Migration registration via `Legion::Data::Local.register_migrations`

## [0.1.0] - 2026-03-13

### Added
- Initial release
