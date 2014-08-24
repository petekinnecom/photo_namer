require 'minitest/autorun'
require 'pry'

class RenamerTest < Minitest::Test
  def test_it_all
    `rm ./test/results/* 2> /dev/null`
    `ruby photo_renamer.rb ./test/originals ./test/results`

    # original files are still the same
    originals = [".", "..", "another_image.jpg", "original.jpg", "original_copy_shouldnt_be_copied.jpg", "original_edited_should_have_counter_appended.jpg"]
    assert_equal originals, Dir.entries('test/originals')

    # results named as expected
    results = [".", "..", ".gitkeep", "2012-06-10 23.13.22.jpg", "2013-03-03 17.45.32 2.jpg", "2013-03-03 17.45.32.jpg"]
    assert_equal results, Dir.entries('test/results')
  end

  def teardown
    `rm ./test/results/*`
  end
end
