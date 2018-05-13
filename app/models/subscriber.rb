class Subscriber
  include Mongoid::Document
  include Mongoid::Timestamps

  field :email
end