module EvaluateJavascript
  def js(string)
    page.evaluate_script(string)
  end
end

RSpec.configure do |config|
  config.include EvaluateJavascript, type: :feature
end