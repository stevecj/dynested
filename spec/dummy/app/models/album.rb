class Album < ActiveRecord::Base
  has_many :tracks, :order => :title
  accepts_nested_attributes_for :tracks

  has_many :notes
  accepts_nested_attributes_for :notes

  has_many :reviews, :order => :review
  accepts_nested_attributes_for :reviews
end
