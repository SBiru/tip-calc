class HistoryTracker
  include Mongoid::History::Tracker

  def change_string
    if original[:locked] && !modified[:locked]
      '<b>Unlocked</b>'
    else
      '<b>Locked</b>'
    end.concat(" by <b>#{ modifier.try(:email).presence || 'system' }</b> at #{ created_at.strftime("%Y-%m-%d \(%H:%M:%S\) %Z") }").html_safe
  end
end