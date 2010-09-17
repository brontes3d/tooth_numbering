class SharkBite < ActiveRecord::Base
  
  include ToothNumbering
  
end

ToothNumbering::Systems.class_eval do
  
  define_system(:pstns) do
    
    common_name "Pacific Shark Tooth Numbering System"
    
    upper_right '14',  '15',  '16',  '17',  '18',  '19',  '20',  '21',  '22',  '23',  '24',  '25',  '26'
    
    upper_left '1',  '2',  '3',  '4',  '5',  '6',  '7',  '8',  '9',  '10',  '11',  '12',  '13'
    
    lower_right 'L26', 'L25', 'L24', 'L23', 'L22', 'L21', 'L20', 'L19', 'L18', 'L17', 'L16', 'L15', 'L14'
    
    lower_left 'L1', 'L2', 'L3', 'L4', 'L5', 'L6', 'L7', 'L8', 'L9', 'L10', 'L11', 'L12', 'L13'
            
  end
  
  define_system(:reprep) do
    
    common_name "The Repetetive and Confusing System"
    
    upper_right '1', '2', '3', '4'

    upper_left  '4', '3', '2', '1'

    lower_right '1', '3', '2', '4'

    lower_left  '3', '1', '4', '2'
    
    
  end
    
  
end