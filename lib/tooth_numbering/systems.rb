class ToothNumbering::Systems
  @@systems = {}
  
  def self.systems_hash
    @@systems
  end
  
  class Definer
    def initialize(for_system)
      @for_system = for_system
    end
    def common_name(arg)
      @for_system.common_name = arg
    end
    def upper_left(*args)
      @for_system.upper_left_numbers = args
    end
    def upper_right(*args)
      @for_system.upper_right_numbers = args
    end
    def lower_left(*args)
      @for_system.lower_left_numbers = args
    end
    def lower_right(*args)
      @for_system.lower_right_numbers = args
    end
  end
  
  attr_accessor :system_name, :common_name  
  attr_accessor :upper_left_numbers, :upper_right_numbers, :lower_left_numbers, :lower_right_numbers
  def initialize(system_name, &definition)
    self.system_name = system_name
    Definer.new(self).instance_eval(&definition)
  end
  
  def compare_arch_order(a, b)
    arch_order = ['upper_right', 'upper_left', 'lower_right', 'lower_left']
    unless arch_order.index(a.arch)
      raise ArgumentError, "Unknown arch: #{a.arch} for #{a.tooth_number} on #{system_name}"
    end
    unless arch_order.index(b.arch)
      raise ArgumentError, "Unknown arch: #{b.arch} for #{b.tooth_number} on #{system_name}"
    end
    arch_order.index(a.arch) <=> arch_order.index(b.arch)
  end
  
  def compare_tooth_order(a, b)
    # puts "compare_tooth_order: #{a} #{b}"
    if (arch_compare = compare_arch_order(a, b)) && arch_compare != 0
      return arch_compare
    end
    arch_numbers = self.send("#{a.arch}_numbers")
    unless arch_numbers.index(a.tooth_number)
      raise ArgumentError, "Tooth number #{a.tooth_number} not found on arch #{a.arch} on #{system_name}"
    end
    unless arch_numbers.index(b.tooth_number)
      raise ArgumentError, "Tooth number #{a.tooth_number} not found on arch #{a.arch} on #{system_name}"
    end
    arch_numbers.index(a.tooth_number) <=> arch_numbers.index(b.tooth_number)
  end
  
  def arch_for(tooth_number)
    upper_left_numbers.each do |tn|
      return 'upper_left' if tn == tooth_number
    end
    upper_right_numbers.each do |tn|
      return 'upper_right' if tn == tooth_number
    end
    lower_left_numbers.each do |tn|
      return 'lower_left' if tn == tooth_number
    end
    lower_right_numbers.each do |tn|
      return 'lower_right' if tn == tooth_number
    end
    return "(unknown)"
  end
  
  def self.define_system(symbol_name, &definition)
    @@systems[symbol_name.to_sym] = ToothNumbering::Systems.new(symbol_name, &definition)
  end
    
  def self.system_called(name)
    return nil if name.blank?
    @@systems[name.to_sym]
  end
  
  #http://en.wikipedia.org/wiki/Universal_numbering_system_(dental)
  
  define_system(:us_adult) do
    
    common_name "Universal/National System for permanent (adult) dentition"
    
    upper_right "8", "7", "6", "5", "4", "3", "2", "1"
    
    upper_left "16", "15", "14", "13", "12", "11", "10", "9"
    
    lower_right "25", "26", "27", "28", "29", "30", "31", "32"
    
    lower_left "17", "18", "19", "20", "21", "22", "23", "24"
    
  end
  
  define_system(:us_child) do
    
    common_name "Universal/National System for deciduous (child) dentition"
    
    upper_right "E", "D", "C", "B", "A"
    
    upper_left  "J", "I", "H", "G", "F"
    
    lower_right "P", "Q", "R", "S", "T"
    
    lower_left  "K", "L", "M", "N", "O"
    
  end
  
  #http://en.wikipedia.org/wiki/FDI_World_Dental_Federation_notation
  
  define_system(:fdi_adult) do
    
    common_name "FDI World Dental Federation notation for permanent (adult) dentition"
    
    upper_right "18", "17", "16", "15", "14", "13", "12", "11"
    
    upper_left "21", "22", "23", "24", "25", "26", "27", "28"
    
    lower_right "48", "47", "46", "45", "44", "43", "42", "41"
    
    lower_left "31", "32", "33", "34", "35", "36", "37", "38"
    
  end
  
  define_system(:fdi_child) do
    
    common_name "FDI World Dental Federation notation for deciduous (child) dentition"
    
    upper_right "55", "54", "53", "52", "51"
    
    upper_left "61", "62", "63", "64", "65"
    
    lower_right "85", "84", "83", "82", "81"
    
    lower_left "71", "72", "73", "74", "75"
    
  end
  
  #http://en.wikipedia.org/wiki/Palmer_notation
  
  define_system(:palmer_adult) do
    
    common_name "Palmer Adult System"
    
    upper_right "8┘", "7┘", "6┘", "5┘", "4┘", "3┘", "2┘", "1┘"
    
    upper_left "└1", "└2", "└3", "└4", "└5", "└6", "└7", "└8"
    
    lower_right "8┐", "7┐", "6┐", "5┐", "4┐", "3┐", "2┐", "1┐"
    
    lower_left "┌1", "┌2", "┌3", "┌4", "┌5", "┌6", "┌7", "┌8"
    
  end
  
  define_system(:palmer_child) do
    
    common_name "Palmer Child System"
    
    upper_right "E┘", "D┘", "C┘", "B┘", "A┘"
    
    upper_left  "└A", "└B", "└C", "└D", "└E"
                                           
    lower_right "E┐", "D┐", "C┐", "B┐", "A┐"
                                           
    lower_left  "┌A", "┌B", "┌C", "┌D", "┌E"
    
  end
  
end