require "minitest/autorun"
require "sfdsort"

class SFDSortTest < Minitest::Test
  def openFont(filename)
    return SFDSort.parseSfd("#{__dir__}/assets/#{filename}")
  end

  def test_parseSfd_open1
    $prm = SFDSort.defaultSettings
    parsed = openFont("UnicodeOrdered.sfd")
    refute_nil parsed
    for i in %w[a b c]
      assert_includes parsed[:glyphs], i
    end
    assert_equal "h", parsed[:order][1][:name]
    assert_equal 0x68, parsed[:order][1][:encoding]
    assert_equal 0x68, parsed[:order][1][:unicode]
    assert_equal 1, parsed[:order][1][:glyphOrder]
    refute_includes parsed[:glyphs], "foo"
    refute parsed[:encodingIsOriginal]
  end

  def test_parseSfd_open2
    $prm = SFDSort.defaultSettings
    parsed = openFont("GlyphOrdered-DefaultGlyphs.sfd")
    refute_nil parsed
    for i in %w[a b c]
      assert_includes parsed[:glyphs], i
    end
    assert_equal "h", parsed[:order][1][:name]
    assert_equal 1, parsed[:order][1][:encoding]
    assert_equal 0x68, parsed[:order][1][:unicode]
    assert_equal 1, parsed[:order][1][:glyphOrder]
    refute_includes parsed[:glyphs], "foo"
    assert parsed[:encodingIsOriginal]
  end

  def test_parseSfd_openInvalid
    $prm = SFDSort.defaultSettings
    assert_raises(SFDSort::InvalidFileError) do
      openFont("NotAFont.txt")
    end
  end

  def test_sortOtfFeatName
    parsed = SFDSort.blankParsed
    $prm = SFDSort.defaultSettings
    parsed[:header] = <<FINIS.split(/\r?\n/)
SplineFontDB: 3.2
OtfFeatName: 'ss01' 1033 "American English ss01"
OtfFeatName: 'ss02' 1033 "American English ss02"
OtfFeatName: 'ss01' 2057 "British English"
OtfFeatName: 'ss01' 16393 "Indian English"
OtfFeatName: 'ss01' 1036 "Français"
Encoding: UnicodeFull
FINIS

    $prm[:sortOtfFeatName] = false
    result = SFDSort.sortOtfFeatName(parsed)
    assert_equal result[:header], <<FINIS.split(/\r?\n/)
SplineFontDB: 3.2
OtfFeatName: 'ss01' 1033 "American English ss01"
OtfFeatName: 'ss02' 1033 "American English ss02"
OtfFeatName: 'ss01' 2057 "British English"
OtfFeatName: 'ss01' 16393 "Indian English"
OtfFeatName: 'ss01' 1036 "Français"
Encoding: UnicodeFull
FINIS

    $prm[:sortOtfFeatName] = true
    result = SFDSort.sortOtfFeatName(parsed)
    assert_equal result[:header], <<FINIS.split(/\r?\n/)
SplineFontDB: 3.2
OtfFeatName: 'ss01' 1033 "American English ss01"
OtfFeatName: 'ss01' 1036 "Français"
OtfFeatName: 'ss01' 2057 "British English"
OtfFeatName: 'ss01' 16393 "Indian English"
OtfFeatName: 'ss02' 1033 "American English ss02"
Encoding: UnicodeFull
FINIS
  end

  def check_type_and_value(expected, actual)
    assert_equal expected, actual
    assert_kind_of expected.class, actual
  end

  def test_toval
    check_type_and_value 3, SFDSort.toval("3")
    check_type_and_value (-5), SFDSort.toval("-5")
    check_type_and_value 6.5, SFDSort.toval("6.5")
    check_type_and_value (-1.25), SFDSort.toval("-1.25")
  end
end
