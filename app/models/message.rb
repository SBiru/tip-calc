class Message
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name
  field :email
  field :text

  after_create :notify_admin

  def notify_admin
    ["v.e.kozlov@gmail.com", "hello@tipmetric.com"].each do |mail|
      MessageMailer.message_received(self, mail).deliver_now
    end
  end
end