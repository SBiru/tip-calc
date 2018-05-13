class Api::TipOutsController < Api::ApiController
  protect_from_forgery with: :exception
  before_action :authenticate_model!

  def destroy
    calculation = Calculation.find(params[:calculation_id])
    tip_out = calculation.sender_tip_outs.find(params[:id])

    if tip_out.destroy
      render json: true, status: 200
    else
      render json: tip_out.errors.full_messages.join(", "), status: 200
    end
  end

  def tip_out_params
    params.require(:tip_out).permit(:sender, :receiver)
  end
end
