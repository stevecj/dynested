class Album < ActiveRecord::Base
  has_many :tracks
  accepts_nested_attributes_for :tracks
end
