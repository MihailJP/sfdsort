SFDSort
=======

This script reorders glyphs in a spline font database file (of Fontforge).

## Usage

```bash
$ ./sfdsort.rb [options] infile > outfile
```

### Options

- `-e`, `--encoding-order`: Reorders glyphs by encoding. This is the default option.
- `-u`, `--unicode-order`: Reorders glyphs by Unicode codepoints. Alternative Unicode encodings are ignored. Such glyphs that Unicode encoding is -1 (none assigned) will be ordered after all the others.
- `-n`, `--name-order`: Reorders glyphs by name.
- `-d`, `--default-char-first`: Reorders _.notdef_, _.null_, and _nonmarkingreturn_, if exist, before all the others. Among these three, they will be in said order.
