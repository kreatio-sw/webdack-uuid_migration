class School < ActiveRecord::Base
  has_many :students, as: :institution
end
