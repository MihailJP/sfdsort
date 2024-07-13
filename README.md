SFDSort
=======

This script reorders glyphs in a spline font database file (of Fontforge).

## Usage

```bash
$ ./sfdsort.rb [options] infile > outfile
```

### Options

#### Glyph order options

- `-e`, `--encoding-order`: Reorders glyphs by encoding.
- `-u`, `--unicode-order`: Reorders glyphs by Unicode codepoints. Alternative Unicode encodings are ignored. Such glyphs that Unicode encoding is -1 (none assigned) will be ordered after all the others.
- `-n`, `--name-order`: Reorders glyphs by name.
- `-f`, `--custom-order=FILENAME`: Specifies glyph order by file. The file must contain glyph names one per each line. Nonexistent glyph will be ignored (but you will be warned about it). Unspecified glyphs will be ordered after everything else. Use together with one of three options said above if you want to sort unspecified glyphs.
- `-d`, `--default-char-first`: Reorders _.notdef_, _.null_, and _nonmarkingreturn_, if exist, before all the others. Among these three, they will be in said order.

#### Other options

- `-w`, `--drop-wininfo`: Drops WinInfo
- `-H`, `--drop-hint-flag`: Drops Flag `H` from all glyphs
- `-O`, `--drop-open-flag`: Drops Flag `O` from all glyphs
- `-D`, `--deselect-all`: Deselect all points and references in all glyphs
