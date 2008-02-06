# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module TokenAtomizerTests
  def test_localize_with_other_object_raises_argument_error
    assert_raise(ArgumentError) { @atomizer.localize(nil) }
  end
  
  def test_globalize_with_other_object_returns_object
    assert_equal(Object, @atomizer.globalize(Object))
  end
  
  def test_globalize_integer
    assert_equal("one", @atomizer.globalize(1))
  end
  
  def test_localize_string
    assert_equal(3, @atomizer.localize("three"))
  end
  
  def test_globalize_non_existant_integer_raises_argument_error
    assert_raise(ArgumentError) { @atomizer.globalize(11) }
  end
  
  def test_localize_non_existant_string_creates_new_token_id
    assert_kind_of(Integer, @atomizer.localize('new_token'))
  end
  
  def test_localize_non_existant_string_creates_token_id_greater_than_existing
    assert_operator(5, :<, @atomizer.localize('new_token'))
  end
  
  def test_localize_non_existant_string_is_persistant
    assert_equal(@atomizer.localize('new_token'), @atomizer.localize('new_token'))
  end
  
  def test_globalize_is_inverse_of_localize
    assert_equal('one', @atomizer.globalize(@atomizer.localize('one')))
  end
  
  def test_localize_is_inverse_of_globalize
    assert_equal(2, @atomizer.localize(@atomizer.globalize(2)))
  end
  
  def test_globalize_array
    assert_equal(%w(five two four), @atomizer.globalize([5, 2, 4]))
  end
  
  def test_globalize_array_with_missing_ids_raises_argument_error
    assert_raise(ArgumentError) { @atomizer.globalize([2, 5, 11]) }
  end
  
  def test_localize_array
    assert_equal([1, 4, 2], @atomizer.localize(%w(one four two)))
  end
  
  def test_localize_array_with_duplicates
    assert_equal([1, 1, 2], @atomizer.localize(%w(one one two)))
  end
  
  def test_localize_array_with_new_duplicates
    actual = @atomizer.localize(%w(new_item new_item new_item))
    new_token_id = @atomizer.localize('new_item')
    assert_equal([new_token_id, new_token_id, new_token_id], actual)
  end
  
  def test_localize_array_with_missing_ids_generates_new_ids
    actual = @atomizer.localize(%w(one new_token four two))
    assert_equal([1, @atomizer.localize('new_token'), 4, 2], actual)
  end
  
  def test_localize_is_inverse_of_globalize_with_arrays
    assert_equal([1, 3, 5], @atomizer.localize(@atomizer.globalize([1, 3, 5])))
  end
  
  def test_globalize_is_inverse_of_localize_with_arrays
    assert_equal(%w(one five two), @atomizer.globalize(@atomizer.localize(%w(one five two))))
  end
  
  def test_globalize_hash_keys
    assert_equal({'one' => 23, 'two' => 45, 'three' => 64}, @atomizer.globalize({1 => 23, 2 => 45, 3 => 64}))
  end
  
  def test_globalize_hash_keys_with_missing_id_generates_error
    assert_raise(ArgumentError) { @atomizer.globalize({1 => 23, 72 => 45, 3 => 64}) }
  end
  
  def test_localize_hash_keys
    assert_equal({5 => 23, 3 => 45, 2 => 64}, @atomizer.localize({'five' => 23, 'three' => 45, 'two' => 64}))
  end
  
  def test_localize_hash_keys_with_missing_ids_generates_new_ids
    actual = @atomizer.localize({'five' => 23, 'new_token' => 12, 'three' => 45, 'two' => 64})
    assert_equal({5 => 23, @atomizer.localize('new_token') => 12, 3 => 45, 2 => 64}, actual)
  end
  
  def test_localize_long_string
    @atomizer.localize('a' * 275)
    @atomizer.localize('a' * 300)    
    assert_not_equal(@atomizer.localize('a' * 300), @atomizer.localize('a' * 275))
  end
  
  def test_globalize_array_with_int_and_float_just_changes_int
    assert_equal([1.23, 'one'], @atomizer.globalize([1.23, 1]))
  end
  
  def test_globalize_nested_array_with_int_and_float_just_changes_int
    assert_equal([[1.23, 'one'], [3.45, 'two']], @atomizer.globalize([[1.23, 1], [3.45, 2]]))
  end
end
