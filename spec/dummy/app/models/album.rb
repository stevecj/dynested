class Album < ActiveRecord::Base
  has_many :tracks, :order => :title
  accepts_nested_attributes_for :tracks
end
