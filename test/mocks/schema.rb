ActiveRecord::Schema.define do

  create_table "shark_bites", :force => true do |t|
    t.text  "teeth_involved"
  end

end