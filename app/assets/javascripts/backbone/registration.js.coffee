(->
  registrationView = Backbone.View.extend(
    el: ".registration-wrapper"

    events:
      "click .register-link": "checkTermsAreAgreed"

    isChecked: (e) ->
      $(".terms-block input").is(':checked')

    checkTermsAreAgreed: (e) ->
      unless @isChecked()
        e.preventDefault()
        toastr["error"]("Please accept TipMetric's Terms of Use & Privacy Policy", "Error")
  )

  $(document).ready ->
    Tipcalc.Controllers.registrationView = new registrationView()
)()