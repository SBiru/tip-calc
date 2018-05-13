(->
  BillingView = Backbone.View.extend(
    el: "body.billing"
    container: "#billing-view"
    data: {}
    events:
      'click .card .make-default': 'makeDefaultCard'
      'click .card .delete': 'deleteCard'
      'click .plan-wrapper .cancel': 'cancel'
      "change .period_editable": 'updatePlanPrice'
      "change .use-card": 'chooseCard'
      'click .toggle-billing-pages': 'toggleBillingPages'

    initialize: ->
      @stripe = Stripe(gon.stripe_key);
      @elements = @stripe.elements();
      @renderSubscriptionBlocks()

    oldCardChoosen: ->
      $(".use-card:checked").attr("data-card-id")

    chooseCard: (e) ->
      currentCardCheckbox = $(e.currentTarget)
      isChecked = $(currentCardCheckbox).is(":checked")

      if isChecked
        for card in $(".use-card")
          if $(card).attr("data-card-id") isnt $(currentCardCheckbox).attr("data-card-id")
            $(card).prop('checked', false)

    toggleBillingPages: ->
      if $('body').attr('data-page-rendered') is 'billing'
        @renderStatisticsBlocks()
      else
        @renderSubscriptionBlocks()

    # Main blocks

    renderSubscriptionBlocks: ->
      Tipcalc.Controllers.spinner.show()
      $.ajax
        url: "/billing_user"
        method: "get"
        success: (response) =>
          Tipcalc.Controllers.spinner.hide()
          gon.user_charges = response.user_charges
          gon.stripe_current_user = response.stripe_current_user
          $('body').attr('data-page-rendered', 'billing')
          @renderPage('billing')
          @createCard(gon)
          @bindSubmit(gon)
          @generateCards(gon)
          @updatePlanPrice(gon)
        error: (response) ->
          Tipcalc.Controllers.spinner.hide()

    renderPage: (page) ->
      html = JST["billing/#{ page }"](gon)
      $(@container).html( html )

    subscribe: (e) ->
      companySize = $("[name='company_size']").val()
      billingPeriod = $("[name='billing_period']:checked").val()

      if gon.stripe_plans.periods[billingPeriod] and _.any(_.findWhere(gon.stripe_plans.periods[billingPeriod].plans, {company_size: companySize}))
        planName = @data.planSelected
        Tipcalc.Controllers.spinner.show()

        cardChoosen = @oldCardChoosen() || @cardChoosen

        $.ajax
          url: "/api/subscriptions"
          method: "post"
          data:
            subscription_plan: planName
            cardChoosen: cardChoosen
          success: (response) =>
            toastr["success"]("Subscription created", "Success")
            Tipcalc.Controllers.spinner.hide()
            @clearBillingForm()
          error: (response) ->
            toastr["error"](response.responseText, "Error")
            Tipcalc.Controllers.spinner.hide()
      else
        toastr["error"]("Please choose subscription plan.", "Error")

    clearBillingForm: ->
      # clear card data
      Tipcalc.Controllers.billingView.card.clear()
      $(".use-card").prop('checked', false)

      # clear plan data
      $(".period_editable").prop("checked", false)
      @updatePlanPrice()

    updatePlanPrice: (gon) ->
      companySize = $("[name='company_size']").val()
      billingPeriod = $("[name='billing_period']:checked").val()

      planId = "#{ companySize }-#{ billingPeriod }"
      $(".prices-wrapper").attr("data-plan-selected", planId)
      @data.planSelected = planId

    createCard: (gon) ->
      # Custom styling can be passed to options when creating an Element.
      style = {
        base: {
          # // Add your base input styles here. For example:
          fontSize: '16px',
          lineHeight: '24px'
        }
      };

      # // Create an instance of the card Element
      @card = @card || @elements.create('card', {style: style})

      # // Add an instance of the card Element into the `card-element` <div>
      @card.mount('#card-element');

      @card.addEventListener 'change', (event) ->
        displayError = document.getElementById('card-errors')
        if event.error
          displayError.textContent = event.error.message
        else
          displayError.textContent = ''

    bindSubmit: (gon) ->
      # // Create a token or display an error when the form is submitted.
      @form = document.getElementById('payment-form')
      @form.addEventListener 'submit', (event) =>
        event.preventDefault();

        if _.any(gon.stripe_current_user.subscriptions.data)
          swal(
            title: "",
            text: "You already have subscriptions. Are you sure you want to add another one?",
            type: "info",
            confirmButtonColor: "#28C256",
            confirmButtonText: "Yes",
            showCancelButton: true,
            cancelButtonText: "Cancel"
          , (isConfirmed) =>
            if isConfirmed
              @startSubscriptionProcess()
          )
        else
          @startSubscriptionProcess()

    startSubscriptionProcess: ->
      if @oldCardChoosen()
        @subscribe()
      else
        @stripe.createToken(@card).then( (result) =>
          if result.error
            # // Inform the user if there was an error
            errorElement = document.getElementById('card-errors');
            errorElement.textContent = result.error.message;
          else
            # // Send the token to your server
            @stripeTokenHandler(result.token, true, false);
        )

    stripeTokenHandler: (response, startSubscribing, showNoticeAfterCardCreated) ->
      Tipcalc.Controllers.spinner.show()

      $.ajax
        url: "/api/cards"
        method: "post"
        data:
          token: response.id
        success: (card_response) =>
          if showNoticeAfterCardCreated
            if _.any($(".cards-list div[data-card-id='#{ card_response.id }']"))
              toastr["error"]("This card is already added", "Error")
            else
              toastr["success"]("Card successfully saved", "Success") 
          @generateHtmlForCard(card_response)
          Tipcalc.Controllers.spinner.hide()
          @cardChoosen = card_response.id
          @subscribe() if startSubscribing
        error: (card_response) ->
          toastr["error"](card_response.responseText, "Error")
          Tipcalc.Controllers.spinner.hide()

    # Subscription blocks

    renderStatisticsBlocks: ->
      Tipcalc.Controllers.spinner.show()
      $.ajax
        url: "/billing_user"
        method: "get"
        success: (response) =>
          Tipcalc.Controllers.spinner.hide()
          gon.user_charges = response.user_charges
          gon.stripe_current_user = response.stripe_current_user
          $('body').attr('data-page-rendered', 'subscription')
          @renderPage('subscriptions')
          @createCard(gon)
          @bindCardCreation()
          @generateCards(gon)
          @generateCharges(gon)
          @generateSubscriptions(gon)
        error: (response) ->
          Tipcalc.Controllers.spinner.hide()

    bindCardCreation: (gon) ->
      # // Create a token or display an error when the form is submitted.
      $(".add-card").on 'click', (event) =>
        event.preventDefault();
        @createNewCard()

    createNewCard: (e) ->
      @stripe.createToken(@card).then( (result) =>
        if result.error
          # // Inform the user if there was an error
          errorElement = document.getElementById('card-errors');
          errorElement.textContent = result.error.message;
        else
          # // Send the token to your server
          @stripeTokenHandler(result.token, false, true);
      )

    cancel: (e) ->
      planName = $(e.currentTarget).closest(".plan-wrapper").attr("data-plan-name")
      Tipcalc.Controllers.spinner.show()

      $.ajax
        url: "/api/subscriptions"
        method: "delete"
        data:
          subscription_plan: planName
        success: (response) ->
          $(e.currentTarget).closest(".plan-wrapper").remove()
          toastr["success"]("Subscription canceled", "Success")
          Tipcalc.Controllers.spinner.hide()
        error: (response) ->
          toastr["error"](response.responseText, "Error")
          Tipcalc.Controllers.spinner.hide()

    generateCards: (gon) ->
      for card in gon.stripe_current_user.sources.data
        if gon.stripe_current_user.default_source is card.id
          card.is_default = true
        else
          card.is_default = false
        @generateHtmlForCard(card)

    generateSubscriptions: ->
      for subscription in gon.stripe_current_user.subscriptions.data
        html = JST["billing/subscription"](subscription)
        $(".subscriptions-list").append(html)

    generateCharges: (gondata) ->
      for charge in gondata.user_charges.data
        unless _.contains(gon.hidden_charges, charge.id)
          html = JST["billing/charge"](charge)
          $(".charges-list").append(html)

    generateHtmlForCard: (params) ->
      unless _.any($(".cards-list div[data-card-id='#{ params.id }']"))
        html = JST["billing/card"](params)
        $(".cards-list").append(html)

    makeDefaultCard: (e) ->
      e.preventDefault()
      card_id = $(e.currentTarget).closest(".card").attr('data-card-id')
      Tipcalc.Controllers.spinner.show()

      $.ajax
        url: "/api/cards"
        method: "patch"
        data:
          card_id: card_id
        success: (response) ->
          for card in $(".card")
            $(card).attr('data-card-is-default', false)

          $(".card[data-card-id='#{ card_id }']").attr('data-card-is-default', true)
          toastr["success"]("Card successfully updated", "Success")
          Tipcalc.Controllers.spinner.hide()
        error: (response) ->
          toastr["error"](response.responseText, "Error")
          Tipcalc.Controllers.spinner.hide()

    deleteCard: (e) ->
      e.preventDefault()
      card_div = $(e.currentTarget).closest(".card")
      card_id = $(e.currentTarget).closest(".card").attr('data-card-id')
      Tipcalc.Controllers.spinner.show()

      $.ajax
        url: "/api/cards"
        method: "delete"
        data:
          card_id: card_id
        success: (response) ->
          toastr["success"]("Card successfully removed", "Success")
          card_div.remove()
          Tipcalc.Controllers.spinner.hide()
        error: (response) ->
          toastr["error"](response.responseText, "Error")
          Tipcalc.Controllers.spinner.hide()
  )

  $(document).ready ->
    if $("body").hasClass("billing")
      Tipcalc.Controllers.billingView = new BillingView()
)()