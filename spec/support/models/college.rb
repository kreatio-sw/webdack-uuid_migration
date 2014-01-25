class College < ActiveRecord::Base
  has_many :students, as: :institution
end
