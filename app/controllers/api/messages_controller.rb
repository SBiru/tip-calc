class Api::MessagesController < Api::ApiController
  skip_before_action :authenticate_user!
  skip_before_action :set_info

  respond_to :js

  def create
    message = Message.new(message_params)
    if message.save
      respond_to do |format|
        format.js
      end
    end
  end

  protected

  def message_params
    params.require(:message).permit(:email, :name, :text)
  end
end