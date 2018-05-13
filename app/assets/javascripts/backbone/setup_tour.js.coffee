(->
  SetupTourView = Backbone.View.extend(
    el: "body.setup"
    events:
      "click .start-tour": "startTour"

    startTour: ->
      tour = new Tour({
        name: "setup_tour",
        steps: [
          {
            element: "[data-tour-step='edit-name']",
            title: "Restaurant name",
            content: "Click edit to add or edit name of existing restaurant."
          },
          {
            element: "[data-tour-step='submit-link']",
            title: "Submit link",
            content: "This link is to give employees so that they can submit hours and tips collected or login to see historical individual tip data.",
            placement: "bottom"
          },
          {
            element: "[data-tour-step='areas']",
            title: "Areas",
            content: "Enter all the Areas in the Restaurant. (Bar, Dinning, Bistro etc.)."
          },
          {
            element: "[data-tour-step='shifts']",
            title: "Shifts",
            content: "Enter all the Shifts in the Restaurant (Breakfast, Lunch, Dinner etc.)."
          },
          {
            element: "[data-tour-step='positions']",
            title: "Positions",
            content: "Enter all the Position types in the Restaurant (Server, Bartender, Busser, Runner, Stocker, Barback etc.).",
            placement: "left"
          },
          {
            element: "[data-tour-step='schedule']",
            title: "Schedule",
            content: "This section allows you to select the Shifts available per day for all the Areas...For example In the Dining Area on Sunday you might have only Brunch Shift but Monday to Saturday you have Lunch and Dinner Shifts in the Dining Area. Note: Whatever is selected here will influence the available choices when setting up a Tip Record in the Calculation page. (Please see Tour in Calculation Page).",
            placement: "top"
          },
          {
            element: "[data-tour-step='workload']",
            title: "Workload",
            content: "This section allows you to select the Positions available per shift for all the Areas...For example In the Dining Area during Lunch Shift you might have Servers & Runners working but Dinning Area during Dinner Shift you might have Servers, Runners and Barbacks. Note: Whatever is selected here will influence the available choices when setting up a Tip Record in the Calculation page. (Please see Tour in Calculation Page).",
            placement: "top"
          },
        ],
        backdrop: true
      });

      tour.init();
      tour.restart();
  )

  $(document).ready ->
    if $("body").hasClass("setup")
      Tipcalc.Controllers.setupTourView = new SetupTourView()
)()
