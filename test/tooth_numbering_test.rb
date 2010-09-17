require 'test/unit'
#set rails env CONSTANT (we are not actually loading rails in this test, but activerecord depends on this constant)
RAILS_ENV = 'test' unless defined?(RAILS_ENV)

require 'rubygems'
require 'activerecord'
require "#{File.dirname(__FILE__)}/../init"

#setup active record to use a sqlite database
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => ":memory:")

#load the database schema for this test
load File.expand_path(File.dirname(__FILE__) + "/mocks/schema.rb")
load File.expand_path(File.dirname(__FILE__) + "/mocks/models.rb")

class ToothNumberingTest < Test::Unit::TestCase

  def test_teeth_invovled_are_assignable_from_hash
    shark_bite = SharkBite.new
    
    shark_bite.teeth_involved = YAML.load(%Q{
      --- 
      system: pstns #Pacific shark tooth numbering system
      teeth:
      - tooth_number: 1
        missing: false
        arch: upper_left
      - tooth_number: 2
        missing: true
        arch: upper_left
    })
    shark_bite.save!
    shark_bite.reload
    
    assert shark_bite.teeth_involved.is_a?(Hash), "Expected teeth involved to be serialized, but found #{shark_bite.teeth_involved.class}"
    
    assert(tooth0 = shark_bite.teeth[0])
    assert(tooth1 = shark_bite.teeth[1])
    
    assert_equal("1", tooth0.tooth_number)
    assert_equal(false, tooth0.missing)
    assert_equal("upper_left", tooth0.arch)
    
    assert_equal("2", tooth1.tooth_number)
    assert_equal(true, tooth1.missing)
    assert_equal("upper_left", tooth1.arch)
    
    assert_equal(["1"], shark_bite.teeth_numbers)
    assert_equal(["2"], shark_bite.missing_teeth_numbers)
  end
  
  def test_basic_validations
    # tooth_numbering is required
    shark_bite = SharkBite.new    
    shark_bite.teeth_involved = YAML.load(%Q{
      --- 
      system: pstns
      teeth:
      - missing: false
        arch: upper_right
    })
    assert !shark_bite.valid?, "Expected validation failure when a tooth is specificied without 'tooth_number' "
    assert shark_bite.errors[:teeth_involved]
    assert shark_bite.errors[:teeth_involved].match(/tooth number/)
    
    # missing or not, is required
    shark_bite = SharkBite.new
    shark_bite.teeth_involved = YAML.load(%Q{
      ---
      system: pstns
      teeth:
      - tooth_number: 1
        arch: upper_left
    })
    assert !shark_bite.valid?, "Expected validation failure when a tooth is specificied without 'missing' "
    assert shark_bite.errors[:teeth_involved]
    assert shark_bite.errors[:teeth_involved].match(/missing/)
    
    # arch is required
    shark_bite = SharkBite.new
    shark_bite.teeth_involved = YAML.load(%Q{
      --- 
      system: pstns
      teeth:
      - tooth_number: 1
        missing: false
    })
    assert !shark_bite.valid?, "Expected validation failure when a tooth is specificied without 'arch' "
    assert shark_bite.errors[:teeth_involved]
    assert shark_bite.errors[:teeth_involved].match(/arch/)

    # numbering system is required
    shark_bite = SharkBite.new
    shark_bite.teeth_involved = YAML.load(%Q{
      ---
      teeth:
      - tooth_number: 1
        missing: false
        arch: upper_right
    })
    assert !shark_bite.valid?, "Expected validation failure when numbering system is not specified "
    assert shark_bite.errors[:teeth_involved]
    assert shark_bite.errors[:teeth_involved].match(/system/)

    # error on tooth number arch mismatch
    shark_bite = SharkBite.new
    shark_bite.teeth_involved = YAML.load(%Q{
      ---
      system: pstns
      teeth:
      - tooth_number: 15
        missing: false
        arch: upper_left
    })
    assert !shark_bite.valid?, "Expected validation failure when tooth_number does not match arch specified "
    assert shark_bite.errors[:teeth_involved]
    assert shark_bite.errors[:teeth_involved].match(/arch/)
    assert shark_bite.errors[:teeth_involved].match(/tooth number/)
  end
  
  def test_appropriate_reordering_of_teeth_involved_array
    shark_bite = SharkBite.new
    
    improperly_ordered_hash = YAML.load(%Q{
      --- 
      system: pstns
      teeth:
      - tooth_number: "17"
        missing: false
        arch: upper_right
      - tooth_number: "4"
        missing: true
        arch: upper_left
      - tooth_number: "L24"
        missing: false
        arch: lower_right
      - tooth_number: "L9"
        missing: true
        arch: lower_left
      - tooth_number: "18"
        missing: true
        arch: upper_right
      - tooth_number: "3"
        missing: false
        arch: upper_left
      - tooth_number: "L23"
        missing: false
        arch: lower_right
      - tooth_number: "L10"
        missing: false
        arch: lower_left
    })
    
    properly_ordered_hash = YAML.load(%Q{
      --- 
      system: pstns
      teeth: 
      - tooth_number: "17"
        arch: upper_right
        missing: false
      - tooth_number: "18"
        arch: upper_right
        missing: true
      - tooth_number: "3"
        arch: upper_left
        missing: false
      - tooth_number: "4"
        arch: upper_left
        missing: true
      - tooth_number: L24
        arch: lower_right
        missing: false
      - tooth_number: L23
        arch: lower_right
        missing: false
      - tooth_number: L9
        arch: lower_left
        missing: true
      - tooth_number: L10
        arch: lower_left
        missing: false
    })
    
    shark_bite.teeth_involved = improperly_ordered_hash
    shark_bite.save!
    shark_bite.reload

    assert_equal(properly_ordered_hash, shark_bite.teeth_involved)    
  end
  
  def test_teeth_assignment
    shark_bite = SharkBite.new
    
    hash = YAML.load(%Q{
      --- 
      system: pstns
      teeth:
      - tooth_number: "1"
        missing: false
        arch: upper_left
      - tooth_number: "2"
        missing: true
        arch: upper_left
    })
    shark_bite.teeth_involved = hash
    shark_bite.save!
    shark_bite.reload
  
    assert_equal(hash, shark_bite.teeth_involved)
    
    target_hash = YAML.load(%Q{
      --- 
      system: pstns
      teeth:
      - tooth_number: "15"
        missing: true
        arch: upper_right
      - tooth_number: "1"
        missing: false
        arch: upper_left
      - tooth_number: "3"
        missing: false
        arch: upper_left
    })
    
    shark_bite.teeth_numbers = ["1","3"]
    shark_bite.missing_teeth_numbers = ["15"]

    assert_equal(target_hash, shark_bite.teeth_involved)
  end
  
  def test_teeth_involved_must_be_set_but_can_include_zero_teeth
    shark_bite = SharkBite.new    
    shark_bite.teeth_involved = YAML.load(%Q{
      --- 
      system: pstns
      teeth: []
    })
    assert shark_bite.valid?, "Should be valid with teeth involved: #{shark_bite.teeth_involved.inspect}"
    
    shark_bite.teeth_involved = YAML.load(%Q{
      --- 
      system: pstns
      teeth: 
    })
    assert !shark_bite.valid?, "Should NOT be valid with teeth involved: #{shark_bite.teeth_involved.inspect}"
    
    shark_bite.teeth_involved = YAML.load(%Q{
      --- 
      system: pstns
    })
    assert !shark_bite.valid?, "Should NOT be valid with teeth involved: #{shark_bite.teeth_involved.inspect}"
    
    shark_bite.teeth_involved = {}
    assert !shark_bite.valid?, "Should NOT be valid with teeth involved: #{shark_bite.teeth_involved.inspect}"
    
    shark_bite.teeth_involved = nil
    assert !shark_bite.valid?, "Should NOT be valid with teeth involved: #{shark_bite.teeth_involved.inspect}"
  end
  
  def test_teeth_array_merging    
    hash1 = YAML.load(%Q{
      --- 
      system: reprep
      teeth:
      - tooth_number: "1"
        missing: false
        arch: upper_right
      - tooth_number: "2"
        missing: true
        arch: upper_left
      - tooth_number: "3"
        missing: false
        arch: lower_right
    })
    
    hash2 = YAML.load(%Q{
      --- 
      system: reprep
      teeth: 
      - tooth_number: "1"
        arch: upper_right
        missing: false
      - tooth_number: "2"
        arch: upper_right
        missing: true
      - tooth_number: "4"
        arch: lower_right
        missing: false
      - tooth_number: "3"
        arch: lower_right
        missing: false
    })
    
    bite1 = SharkBite.new    
    bite1.teeth_involved = hash1

    bite2 = SharkBite.new    
    bite2.teeth_involved = hash2
    
    merged = bite1.teeth.merge(bite2.teeth)
    
    assert_equal 5, merged.size
    
    # hash3 = YAML.load(%Q{
    #   --- 
    #   system: reprep
    #   teeth: 
    #   - tooth_number: "1"
    #     arch: upper_right
    #     missing: false
    #   - tooth_number: "2"
    #     arch: upper_right
    #     missing: true
    #   - tooth_number: "2"
    #     missing: true
    #     arch: upper_left      
    #   - tooth_number: "3"
    #     arch: lower_right
    #     missing: false
    #   - tooth_number: "4"
    #     arch: lower_right
    #     missing: false
    # })
    # 
    # bite3 = SharkBite.new
    # bite3.teeth_involved = hash3
    # 
    # assert_equal(bite3.teeth, merged)    
  end
  
  # def test_to_html
  #   shark_bite = SharkBite.new    
  #   shark_bite.teeth_involved = YAML.load(%Q{
  #     --- 
  #     system: pstns #Pacific shark tooth numbering system
  #     teeth:
  #     - tooth_number: 1
  #       missing: false
  #       arch: upper_right
  #     - tooth_number: 2
  #       missing: true
  #       arch: upper_right
  #   })
  #   
  #   assert_equal("<span class='involved_tooth'>1</span> <span class='missing_tooth'>2</span>",
  #     shark_bite.teeth.to_html)
  # end
  
end
