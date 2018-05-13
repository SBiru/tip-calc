(->
  CalculationTourView = Backbone.View.extend(
    el: "body.calculation"
    events:
      "click .start-tour": "startTour"

    startTour: ->
      tour = new Tour({
        name: "calculation_tour",
        steps: [
          {
            element: "[data-tour-step='date']",
            title: "Date",
            content: "Choose Date you would like to enter Tip Data."
          },
          {
            element: "[data-tour-step='area']",
            title: "Area",
            content: "Choose Area you would like to enter Tip Data."
          },
          {
            element: "[data-tour-step='shift']",
            title: "Shift",
            content: "Choose Shift you would like to enter Tip Data. Note: depending on the date and area selected certain shifts may not be available due to configuration in the Setup page. For example Dinner may only be selected for Tuesdays in the Setup page therefore you will only see Dinner shift available in this dropdown box if the date today is Tuesday. Please refer to Setup page."
          },
          {
            element: "[data-tour-step='source-position']",
            title: "Position",
            content: "Choose position(s) that collect tips for the shift selected. Note: Only select positions that will be collecting tips like Server, Bartender. Do NOT select all positions in that shift...TipMetric already knows all positions in that shift based on configuration in the Setup page."
          },
          {
            element: "[data-tour-step='teams-quantity']",
            title: "Teams quantity",
            content: "Select the number of teams working during the shift selected. If there are no teams choose 1. It means everyone is working as 1 Team.",
            placement: "left"
          },
          {
            element: "[data-tour-step='show']",
            title: "Show calculation",
            content: "Press the \"Show\" button to display tables to enter percentage/ points per position, employee working during the shift, hours worked per employee, tips collected and sales.",
            placement: "left"
          },
          {
            element: "[data-tour-step='percents']",
            title: "Percents",
            content: "Enter percentages for each position for the shift."
          },
          {
            element: "[data-tour-step='tip-outs']",
            title: "Tip outs",
            content: "Click here to enter Tip-Outs for another area if available."
          },
          {
            element: "#distributions-list > div > div:first-child [data-tour-step='add-employee']",
            title: "Adding employee",
            content: "Press \"+Employee\" to add Employee names, hours, sales and/or tips collected working the shift selected.",
            placement: "left"
          },
          {
            element: "#distributions-list > div > div:first-child [data-tour-step='employee-id']",
            title: "Adding employee",
            content: "Select Employee that works the position."
          },
          {
            element: "#distributions-list > div > div:first-child [data-tour-step='employee-hours']",
            title: "Hours",
            content: "Input hours worked for that shift."
          },
          {
            element: "#distributions-list > div > div:first-child [data-tour-step='employee-tips-collected']",
            title: "Tips collected",
            content: "Enter Credit Card Tips and Cash Tips Collected"
          },
          {
            element: "#distributions-list > div > div:first-child [data-tour-step='employee-tips-sales']",
            title: "Sales",
            content: "Enter Sales for the Tips Collected."
          },
          {
            element: "[data-tour-step='show-tip-outs']",
            title: "Tip outs",
            content: "Click here to see Tip-Out data per employee if there are any Tip-Outs.",
            placement: "left"
          },
          {
            element: "[data-tour-step='save-calculation']",
            title: "Saving",
            content: "Click Here to Save Tip record for Date + Area + Shift selected in Steps 1 – 4.",
            placement: "left"
          },
          {
            element: "[data-tour-step='history']",
            title: "History",
            content: "Click Calendar icon to go to History Page and see Tip record just created and also previously created Tip Records.",
            placement: "left"
          }
        ],
        backdrop: true
      });

      tour.init();
      tour.restart();
  )

  $(document).ready ->
    if $("body").hasClass("calculation")
      Tipcalc.Controllers.calculationTourView = new CalculationTourView()
)()
