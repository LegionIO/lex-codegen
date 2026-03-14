# lex-codegen

Code generation engine for LegionIO extensions. Scaffolds complete `lex-*` gem trees from scratch, renders individual ERB templates, validates existing extension structure, and generates companion RSpec files. Used by the `legion lex create` CLI command and by agentic swarm pipelines.

## Installation

Add to your Gemfile or gemspec:

```ruby
gem 'lex-codegen'
```

Or install directly:

```bash
gem install lex-codegen
```

## Usage

### Scaffold a complete extension

```ruby
require 'legion/extensions/codegen'

client = Legion::Extensions::Codegen::Client.new(base_path: '/path/to/output')

result = client.scaffold_extension(
  name:        'myextension',
  module_name: 'Myextension',
  description: 'Does something useful',
  helpers:     ['config'],
  runner_methods: [
    { name: 'run_job', params: ['job_id:'] },
    { name: 'check_status', params: ['job_id:', 'verbose: false'] }
  ]
)

result[:success]        # => true
result[:path]           # => '/path/to/output/lex-myextension'
result[:files_created]  # => 15
```

This writes a fully structured gem including gemspec, Gemfile, .rubocop.yml, GitHub Actions CI workflow, .rspec, .gitignore, LICENSE, version.rb, entry point, client, helpers, runners, and RSpec files for all of the above.

### Generate a single file

```ruby
result = client.generate_file(
  template_type: :runner,
  output_path:   '/tmp/myrunner.rb',
  variables: {
    module_name:          'Myextension',
    gem_name_underscored: 'myextension',
    runner_class:         'RunJob',
    methods: [{ name: 'run_job', params: ['job_id:'] }]
  }
)

result[:bytes]  # => number of bytes written
```

### Render a template to a string (without writing to disk)

```ruby
runner = Legion::Extensions::Codegen::Runners::Template

content = runner.render_template(
  template_type: :version,
  variables: { module_name: 'Myextension', gem_version: '0.1.0' }
)

puts content[:content]
# frozen_string_literal: true
# module Legion::Extensions::Myextension; VERSION = '0.1.0'; end
```

### List available templates

```ruby
runner.list_templates
# => { success: true, templates: [:gemspec, :gemfile, :rubocop, :ci, :rspec, :gitignore,
#                                  :license, :version, :entry_point, :spec_helper, :runner, :client] }
```

### Inspect required variables for a template

```ruby
runner.template_variables(template_type: :gemspec)
# => { success: true, template_type: :gemspec,
#      required_variables: [:gem_name, :module_name, :description, :author, :email,
#                           :ruby_version, :license, :extra_deps] }
```

### Validate an existing extension

```ruby
validator = Legion::Extensions::Codegen::Runners::Validate

# Check directory structure
validator.validate_structure(path: '/path/to/lex-myextension')
# => { valid: true, missing: [], present: ['Gemfile', '.rubocop.yml', ...] }

# Check rubocop config
validator.validate_rubocop_config(path: '/path/to/lex-myextension')
# => { valid: true, issues: [] }

# Check gemspec fields
validator.validate_gemspec(path: '/path/to/lex-myextension')
# => { valid: true, issues: [], path: '/path/to/lex-myextension/lex-myextension.gemspec' }
```

### Generate spec files directly

```ruby
spec_gen = Legion::Extensions::Codegen::Helpers::SpecGenerator.new

# Runner spec
puts spec_gen.generate_runner_spec(
  module_name:  'Myextension',
  runner_name:  'run_job',
  methods:      [{ name: 'run_job', params: ['job_id:'] }]
)

# Client spec
puts spec_gen.generate_client_spec(module_name: 'Myextension')

# Helper spec
puts spec_gen.generate_helper_spec(
  module_name:  'Myextension',
  helper_name:  'config',
  methods:      [{ name: 'load', params: [] }]
)
```

## Available Templates

| Template | Generates |
|----------|-----------|
| `gemspec` | `lex-name.gemspec` |
| `gemfile` | `Gemfile` with gemspec + test group |
| `rubocop` | `.rubocop.yml` with LegionIO defaults |
| `ci` | `.github/workflows/ci.yml` (calls shared reusable workflow) |
| `rspec` | `.rspec` with `--format documentation` |
| `gitignore` | `.gitignore` with standard Ruby entries |
| `license` | `LICENSE` (MIT) |
| `version` | `lib/legion/extensions/<name>/version.rb` |
| `entry_point` | `lib/legion/extensions/<name>.rb` |
| `spec_helper` | `spec/spec_helper.rb` with Legion::Logging stub |
| `runner` | One runner module with stubbed methods |
| `client` | `Client` class including runner modules |

## Defaults

| Setting | Default |
|---------|---------|
| Ruby version | `3.4` |
| License | `MIT` |
| Author | `Esity` |
| Email | `matthewdiverson@gmail.com` |
| Gem version | `0.1.0` |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT. See [LICENSE](LICENSE).
