module ToothNumbering
  
  class Tooth
    attr_accessor :tooth_number, :missing, :arch
    def initialize(from_hash)
      self.tooth_number = from_hash['tooth_number'].to_s
      self.missing = from_hash['missing']
      self.arch = from_hash['arch']
    end
    def ==(arg)
      (arg.is_a?(Tooth) &&
        arg.arch == self.arch &&
        arg.tooth_number == self.tooth_number)
    end
  end
  
  class Teeth < Array
    def initialize(thing_with_teeth_involved)
      @thing_with_teeth_involved = thing_with_teeth_involved
      unless @thing_with_teeth_involved &&
             @thing_with_teeth_involved.teeth_involved &&
             @thing_with_teeth_involved.teeth_involved['teeth'] &&
             @thing_with_teeth_involved.teeth_involved['teeth'].is_a?(Array)
        return
      end
      @thing_with_teeth_involved.teeth_involved['teeth'].each do |hash_of_tooth|
        self << Tooth.new(hash_of_tooth)
      end
    end
    def add_tooth(tooth_hash)
      self << Tooth.new(tooth_hash)
      @thing_with_teeth_involved.teeth_involved['teeth'] << tooth_hash
    end
    def remove_tooth(tooth)
      if i = self.index(tooth)
        self.delete_at(i)
        @thing_with_teeth_involved.teeth_involved['teeth'].delete_at(i)
      end
    end
    def to_serializable_array
      self.collect do |tooth|
        { 'tooth_number' => tooth.tooth_number,
          'arch' => tooth.arch,
          'missing' => tooth.missing }
      end
    end
    def merge(with_other_array_of_teeth_involved)
      to_return = Teeth.new(nil)
      self.each do |tooth|
        to_return << tooth
      end
      with_other_array_of_teeth_involved.each do |other_tooth|
        dup = false
        self.each do |tooth|
          dup ||= (tooth == other_tooth)
        end
        unless dup
          to_return << other_tooth
        end
      end
      to_return
    end
  end
  
  def self.included(base)
    base.class_eval do
      if self.respond_to?(:serialize)
        serialize :teeth_involved
      
        def teeth_involved=(arg)
          self.write_attribute(:teeth_involved, arg)
          put_teeth_in_order
        end        
      end
            
      if self.respond_to?(:validate)
        validate do |thing|
          if thing.teeth_involved.blank?
            thing.errors.add(:teeth_involved, 
              " cannot be blank")          
          else
            thing.teeth.each do |tooth|
              if tooth.tooth_number.blank?
                thing.errors.add(:teeth_involved, 
                  " can't have any blank tooth numbers")
              end
              if tooth.missing.nil?
                thing.errors.add(:teeth_involved, 
                  " must specify whether each tooth is missing (unspecified for #{tooth.tooth_number})")
              end
              if tooth.arch.blank?
                thing.errors.add(:teeth_involved, 
                  " must specify arch for each tooth (unspecified for #{tooth.tooth_number})")
              end
              if !tooth.tooth_number.blank? && !tooth.arch.blank? && thing.tooth_numbering_system
                if thing.tooth_numbering_system.arch_for(tooth.tooth_number) != tooth.arch
                  thing.errors.add(:teeth_involved, 
                    " must put teeth on valid arches (tooth number #{tooth.tooth_number} on arch #{tooth.arch} is invalid)")
                end
              end
            end
            unless thing.teeth_involved['teeth'].is_a?(Array)
              thing.errors.add(:teeth_involved, 
                " must have an array of teeth (it can be empty)")
            end
            if thing.tooth_numbering_system.blank?
              thing.errors.add(:teeth_involved, 
                " must specify tooth numbering system used")          
            end
          end
        end
      end
      
    end
  end
  
  def put_teeth_in_order
    return unless self.teeth_involved && self.teeth_involved['teeth']
    # puts "must sort array: " + self.teeth.inspect
    
    self.teeth.sort! do |a, b|
      tooth_numbering_system.compare_tooth_order(a, b)
    end
      
    self.teeth_involved['teeth'] = self.teeth.to_serializable_array
  end
  
  def tooth_numbering_system
    return nil unless self.teeth_involved
    called = self.teeth_involved['system']
    system_found = ToothNumbering::Systems.system_called(called)
    unless system_found || called.blank?
      raise ArgumentError, "Unknown tooth numbering system #{called}"
    end
    system_found
  end
  
  def teeth
    return nil unless self.teeth_involved
    unless @teeth_t_i == self.teeth_involved
      @teeth = Teeth.new(self)
      @teeth_t_i = self.teeth_involved.dup
    end
    return @teeth
  end
  
  #This method is needed because:
  # if you set teeth_numbers first and there are existing missing_teeth in an incompatible numbering format, 
  # then put_teeth_in_order will fail
  # OR if you set missing_teeth_numbers first and there are existing teeth in an incompatible numbering format, 
  # then put_teeth_in_order will fail
  # So you have to set both, and then put_teeth_in_order
  # and put_teeth_in_order could still fail... 
  # but only if the combined set of teeth_numbers is invalid for the format
  # which means that it's failing correctly
  def set_teeth(as)
    self.set_teeth_numbers(as[:teeth_numbers], false)
    self.set_missing_teeth_numbers(as[:missing_teeth_numbers], false)
    self.put_teeth_in_order
  end
  
  def teeth_numbers
    return [] unless teeth
    teeth.select{ |t| !t.missing }.collect{ |t| t.tooth_number }
  end
  
  def teeth_numbers=(nums)
    set_teeth_numbers(nums)
  end
  def set_teeth_numbers(nums, order_teeth = true)
    raise ArgumentError, "Can't use teeth_numbers= with uninitialized 'teeth_involved'" unless self.teeth
    nums ||= []
    to_set = nums.collect(&:to_s)
    teeth.dup.each do |tooth|
      unless tooth.missing
        if to_set.include?(tooth.tooth_number)
          to_set.delete(tooth.tooth_number)
        else
          teeth.remove_tooth(tooth)
        end
      end
    end
    to_set.each do |tooth_number|
      teeth.add_tooth('tooth_number' => tooth_number, 'missing' => false, 'arch' => tooth_numbering_system.arch_for(tooth_number))
    end
    if order_teeth
      put_teeth_in_order
    end
  end
  
  def missing_teeth_numbers
    return [] unless teeth
    teeth.select{ |t| t.missing }.collect{ |t| t.tooth_number }    
  end
  
  def missing_teeth_numbers=(nums)
    set_missing_teeth_numbers(nums)
  end
  def set_missing_teeth_numbers(nums, order_teeth = true)
    raise ArgumentError, "Can't use missing_teeth_numbers= with uninitialized 'teeth_involved'" unless self.teeth
    nums ||= []
    to_set = nums.collect(&:to_s)
    teeth.dup.each do |tooth|
      if tooth.missing
        if to_set.include?(tooth.tooth_number)
          to_set.delete(tooth.tooth_number)
        else
          teeth.remove_tooth(tooth)
        end
      end
    end
    to_set.each do |tooth_number|
      teeth.add_tooth('tooth_number' => tooth_number, 'missing' => true, 'arch' => tooth_numbering_system.arch_for(tooth_number))
    end
    if order_teeth
      put_teeth_in_order
    end
  end
  
end