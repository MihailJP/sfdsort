# SFDSort

This script reorders glyphs in a spline font database file (of Fontforge).

## Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternatively, replace this section with instructions to install your gem from git if you don't plan to release to RubyGems.org.

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

## Usage

```bash
sfdsort [options] infile > outfile
```

### Options

#### Glyph order options

- `-e`, `--encoding-order`: Reorders glyphs by encoding.
- `-u`, `--unicode-order`: Reorders glyphs by Unicode codepoints. Alternative
  Unicode encodings are ignored. Such glyphs that Unicode encoding is -1 (none
  assigned) will be ordered after all the others.
- `-n`, `--name-order`: Reorders glyphs by name.
- `-f`, `--custom-order=FILENAME`: Specifies glyph order by file. The file
  must contain glyph names one per each line. Nonexistent glyph will be
  ignored (but you will be warned about it). Unspecified glyphs will be
  ordered after everything else. Use together with one of three options said
  above if you want to sort unspecified glyphs.
- `-d`, `--default-char-first`: Reorders _.notdef_, _.null_, _CR_ (or
  _nonmarkingreturn_), and _space_, if exist, before all the others. Among
  these four, they will be in said order.

#### Other options

- `-w`, `--drop-wininfo`: Drops WinInfo
- `-H`, `--drop-hint-flag`: Drops Flag `H` from all glyphs
- `-O`, `--drop-open-flag`: Drops Flag `O` from all glyphs
- `-D`, `--deselect-all`: Deselect all points and references in all glyphs
- `-R`, `--decompose-nested-references`: Decompose nested references into
  single-level ones

> [!NOTE]
> Decomposing nested references may cause unused glyphs. SFDSort will not drop
> such glyphs.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/MihailJP/sfdsort.
