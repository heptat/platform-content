require 'mongoid'

# this will have content specific user fields
class User
  include Mongoid::Document

  field :uid, type: String

  validates_presence_of       :uid

  def to_param
    self.uid
  end

end

