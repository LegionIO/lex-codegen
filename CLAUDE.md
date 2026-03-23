# lex-codegen: Code Generation Engine for LegionIO

**Repository Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-core/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Legion Extension that provides code generation for LegionIO extensions. Scaffolds complete new LEX gems from scratch, renders individual ERB templates, validates existing extension structure and configuration, and generates companion RSpec files. Used by the `legion lex create` CLI command and by agentic swarm pipelines that construct new extensions programmatically.

**GitHub**: https://github.com/LegionIO/lex-codegen
**License**: MIT
**Version**: 0.1.3

## Architecture

```
Legion::Extensions::Codegen
├── Runners/
│   ├── Generate       # Scaffold entire extension trees; generate individual files
│   ├── Template       # List templates, render a template, inspect required variables
│   └── Validate       # Check extension directory structure, rubocop config, gemspec fields
├── Helpers/
│   ├── Constants      # All ERB template strings + defaults (author, version, ruby, license)
│   ├── TemplateEngine # ERB renderer; isolates each render into a fresh binding
│   ├── SpecGenerator  # Builds RSpec source strings for runners, clients, helpers
│   └── FileWriter     # Writes rendered content to disk, creates directories as needed
└── Client             # Thin wrapper; includes all three runner modules
```

No explicit actors directory. The framework auto-generates subscription actors for each runner.

## Gem Info

| Field | Value |
|-------|-------|
| Gem name | `lex-codegen` |
| Module | `Legion::Extensions::Codegen` |
| Version | `0.1.3` |
| Ruby | `>= 3.4` |
| Runtime dep | `erb` (stdlib, declared explicitly) |

## File Structure

```
lex-codegen/
├── lex-codegen.gemspec
├── Gemfile
├── lib/
│   └── legion/
│       └── extensions/
│           ├── codegen.rb                        # Entry point; requires all helpers/runners/client
│           └── codegen/
│               ├── version.rb
│               ├── client.rb                     # Client class; includes all three runner modules
│               ├── helpers/
│               │   ├── constants.rb              # TEMPLATE_MAP, TEMPLATE_TYPES, all ERB strings
│               │   ├── template_engine.rb        # TemplateEngine class (ERB renderer)
│               │   ├── spec_generator.rb         # SpecGenerator class (RSpec source builder)
│               │   └── file_writer.rb            # FileWriter class (disk writer)
│               └── runners/
│                   ├── generate.rb               # scaffold_extension, generate_file
│                   ├── template.rb               # list_templates, render_template, template_variables
│                   └── validate.rb               # validate_structure, validate_rubocop_config, validate_gemspec
└── spec/
```

## Key Constants

Defined in `Helpers::Constants`:

| Constant | Value |
|----------|-------|
| `TEMPLATE_TYPES` | `[:gemspec, :gemfile, :rubocop, :ci, :rspec, :gitignore, :license, :version, :entry_point, :spec_helper, :runner, :client]` |
| `DEFAULT_RUBY_VERSION` | `'3.4'` |
| `DEFAULT_LICENSE` | `'MIT'` |
| `DEFAULT_AUTHOR` | `'Esity'` |
| `DEFAULT_EMAIL` | `'matthewdiverson@gmail.com'` |
| `DEFAULT_GEM_VERSION` | `'0.1.0'` |
| `TEMPLATE_MAP` | Hash mapping each symbol in `TEMPLATE_TYPES` to its ERB string |

Defined in `Runners::Template`:

| Constant | Value |
|----------|-------|
| `TEMPLATE_REQUIRED_VARS` | Hash mapping each template type to its required variable keys |

Defined in `Runners::Validate`:

| Constant | Value |
|----------|-------|
| `REQUIRED_FILES` | `['Gemfile', '.rubocop.yml', 'spec/spec_helper.rb']` |
| `REQUIRED_RUBOCOP_KEYS` | `['AllCops', 'Layout/LineLength', 'Metrics/MethodLength', 'Style/FrozenStringLiteralComment']` |
| `REQUIRED_GEMSPEC_FIELDS` | `['name', 'version', 'authors', 'email', 'summary', 'description', 'homepage', 'license']` |

## Runners

### Generate (`Runners::Generate`)

`extend self` — all methods callable on the module directly.

**`scaffold_extension(name:, module_name:, description:, category: :cognition, helpers: [], runner_methods: [], base_path: nil, **)`**
- Creates a complete extension directory tree at `<base_path>/lex-<name>/`
- Writes: gemspec, Gemfile, .rubocop.yml, .github/workflows/ci.yml, .rspec, .gitignore, LICENSE, version.rb, entry point, spec_helper, client, one file per helper, one runner file + one runner spec per `runner_methods` entry, client_spec
- `helpers` accepts either plain strings (helper name) or hashes `{ name:, methods: [] }`
- `runner_methods` accepts hashes with `:name` and `:params` keys; each becomes one runner module and one spec file
- Returns `{ success: true, path:, files_created:, name: }` or `{ success: false, error: }`

**`generate_file(template_type:, output_path:, variables: {}, **)`**
- Renders a single named template and writes it to `output_path`
- Creates parent directories via `FileUtils.mkdir_p`
- Returns `{ success: true, path:, bytes: }` or `{ success: false, error: }`

### Template (`Runners::Template`)

`extend self` — all methods callable on the module directly.

**`list_templates(**)`**
- Returns `{ success: true, templates: <array of 12 template type symbols> }`

**`render_template(template_type:, variables: {}, **)`**
- Renders the named template with provided variables
- Returns `{ success: true, content:, template_type: }` or `{ success: false, error: }`

**`template_variables(template_type:, **)`**
- Returns the list of required variable keys for the given template type
- Returns `{ success: true, template_type:, required_variables: [] }` or `{ success: false, error: }`

### Validate (`Runners::Validate`)

`extend self` — all methods callable on the module directly.

**`validate_structure(path:, **)`**
- Checks for required files: Gemfile, .rubocop.yml, spec/spec_helper.rb, *.gemspec, lib entry point, version.rb
- Returns `{ valid:, missing: [], present: [] }` or adds `:error` key on ArgumentError

**`validate_rubocop_config(path:, **)`**
- Parses `.rubocop.yml` and checks for required top-level keys
- Verifies `AllCops/TargetRubyVersion` equals `DEFAULT_RUBY_VERSION` (`'3.4'`)
- Returns `{ valid:, issues: [] }`

**`validate_gemspec(path:, **)`**
- Reads the `*.gemspec` file and checks for required field names via string inclusion
- Also checks for `rubygems_mfa_required` metadata and `required_ruby_version`
- Returns `{ valid:, issues: [], path: }`

## Helpers

### TemplateEngine

Class. No persistent state.

**`render(template_type, variables = {})`**
- Looks up `TEMPLATE_MAP[template_type.to_sym]`, raises `ArgumentError` on unknown type
- Delegates to `render_string`

**`render_string(template_string, variables = {})`**
- Renders an arbitrary ERB string with `trim_mode: '-'`
- Each variable becomes a method on a fresh `Object` context — no shared state between renders

### SpecGenerator

Class. No persistent state.

**`generate_runner_spec(module_name:, runner_name:, methods: [])`**
- Returns RSpec source as a string; one `describe` block per method, tests `respond_to` and `{ success: }` key presence

**`generate_client_spec(module_name:, runner_name: nil, methods: [])`**
- Returns RSpec source as a string; tests `instantiates successfully` and `responds_to` each method

**`generate_helper_spec(module_name:, helper_name:, methods: [])`**
- Returns RSpec source as a string; tests instantiation and `responds_to` each method

### FileWriter

Class. Initialized with `base_path:`.

**`write(relative_path, content)`**
- Resolves `File.join(@base_path, relative_path)`, creates parent directories, writes content
- Returns `{ path:, bytes: }`

**`write_all(files)`**
- Accepts a hash of `{ relative_path => content }` and calls `write` for each
- Returns array of `{ path:, bytes: }` results

## Integration Points

- **`legion lex create`** CLI command calls `scaffold_extension` to bootstrap new extension repos
- **`lex-swarm-github`** swarm pipeline uses codegen to produce runner and spec files during automated extension construction
- **`lex-exec`** is the natural companion: codegen produces the files, exec runs `bundle install` and `bundle exec rspec` against the output

## Development Notes

- All runners use `extend self`; methods are callable on the module directly without instantiation
- The `Client` class includes all three runner modules, making all runner methods available on a `Client.new` instance
- `TemplateEngine#binding_with` creates a fresh `Object` subcontext for each render; variable names become singleton methods, not local variables — ERB must reference them without `@` prefix
- `scaffold_extension` accepts `category:` but does not use it (marked with `Lint/UnusedMethodArgument`); present for future routing support
- `generate_client_spec` accepts `runner_name:` but does not use it (same reason)
- Validate methods check file existence by string inclusion on file content, not by loading/evaluating the gemspec

```bash
bundle install
bundle exec rspec     # 82 examples, 0 failures
bundle exec rubocop   # 0 offenses
```

---

**Maintained By**: Matthew Iverson (@Esity)
