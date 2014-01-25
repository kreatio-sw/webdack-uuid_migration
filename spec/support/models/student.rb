class Student < ActiveRecord::Base
  belongs_to :city

  belongs_to :institution, :polymorphic => true
end
