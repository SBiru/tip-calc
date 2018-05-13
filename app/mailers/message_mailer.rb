class MessageMailer < ActionMailer::Base
  default from: "postmaster@sandboxe50d756a3b31491ca31cc6145bdc8518.mailgun.org"

  def message_received(message, email)
    @message = message
    mail(to: email, subject: 'Message from TipMetric')
  end
end