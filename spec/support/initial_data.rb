
def populate_sample_data
  (0..4).each do |i|
    City.create(name: "City #{i}")
    School.create(name: "School #{i}")
    College.create(name: "College #{i}")
  end

  (0..49).each do |i|

    institution= if i.even? then
                   School.where(name: "School #{(i/2)%5}").first
                 else
                   College.where(name: "College #{(i/2)%5}").first
                 end

    Student.create(
        name: "Student #{i}",
        city: City.where(name: "City #{i%5}").first,
        institution: institution
    )
  end
end
