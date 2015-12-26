class Student < ActiveRecord::Base
  belongs_to :city, -> {where('true')}

  belongs_to :institution, -> {where('true')}, :polymorphic => true
end
