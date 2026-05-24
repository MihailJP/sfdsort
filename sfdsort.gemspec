# frozen_string_literal: true

require_relative "lib/sfdsort/version"

Gem::Specification.new do |spec|
  spec.name = "sfdsort"
  spec.version = SFDSort::VERSION
  spec.authors = ["MihailJP"]
  spec.email = ["mihailjp@gmail.com"]

  spec.summary = "Reorders glyphs in a spline font database file (of Fontforge)"
  #spec.description = "TODO: Write a longer description or delete this line."
  spec.homepage = "https://github.com/MihailJP/sfdsort"
  spec.required_ruby_version = ">= 3.1.0"
  spec.licenses = ["Unlicense"]

  #spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  #spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  #spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
