(->
  ReportsView = Backbone.View.extend(
    el: "#reports-view"
    events:
      "click .select-numbers-type button": "selectNumbersType"
      "change [data-required-field='true']": "checkIfDataValid"
      "click form a[data-format]": "getDataByFormat"

    initialize: ->
      @bindStartDate()
      @setEndDate(true)
      @showTotalChart("global")
      @checkIfDataValid()

    bindStartDate: ->
      $('#start').datepicker().on "changeDate", (e) =>
        @setEndDate()

    setEndDate: (initial_date) ->
      startdate = $("#start").datepicker("getDate")
      if initial_date
        date = $("#end").datepicker("getDate")
      else
        date = startdate

      maxDate = moment(startdate).add(6, "day").format("MM/DD/YYYY")
      $('#end').datepicker('remove')
      $("#end").datepicker()
      $("#end").datepicker("setStartDate", startdate)
      $("#end").datepicker("setEndDate", maxDate)
      $("#end").datepicker("setDate", date)

    checkIfDataValid: (e) ->
      fields = $("[data-required-field='true']")
      blankFields = _.filter(fields, (e) ->
        return $(e).val() is null || $(e).val().length is 0 || $(e).val() is undefined
      ) || []

      if _.isEmpty blankFields
        $(".get-html, .get-xlsx").removeAttr("disabled")
      else
        $(".get-html, .get-xlsx").attr("disabled", "disabled")

    getDataByFormat: (e) ->
      e.preventDefault()

      unless $(e.currentTarget).attr("disabled") == "disabled"
        format = $(e.currentTarget).attr("data-format")
        scope = $(e.currentTarget).attr("data-scope")
        if scope is "users"
          action = "/show_reports.#{ format }"
        else if scope is "employees"
          action = "/employees/show_reports.#{ format }"
        form = $(e.currentTarget).closest("form")
        form.attr("action", action)
        Tipcalc.Controllers.spinner.show() if format is 'html'

        if format is 'html'
          setTimeout () ->
            form.find("input[type='submit']").click()
          , 1000
        else if format is 'xlsx'
          swal(
            modalIdentifier: "reports-type",
            title: "",
            text: "What type of report do you want to download?",
            type: "info",
            confirmButtonColor: "#28C256",
            confirmButtonText: "Weekly report"
            showCancelButton: true,
            cancelButtonText: "Daily Report",
            cancelButtonColor: '#28C256'
          , (isDelete) =>
            console.log isDelete
            if isDelete
              $("#excel_report_type").val("weekly")
            else
              $("#excel_report_type").val("daily")

            setTimeout () ->
              form.find("input[type='submit']").click()
            , 1000
          )


          

    selectNumbersType: (e) ->
      $(".select-numbers-type button").removeClass("active")
      $(e.currentTarget).addClass("active")

      showClass = $(e.currentTarget).attr("data-num-type")

      $("[data-type='changeble']").find(".cc, .cash, .global, .tip-outs-cc, .tip-outs-cash").hide()
      $("[data-type='changeble']").find(".#{ showClass }").show()

      @showTotalChart(showClass)

    showTotalChart: (type) ->
      @myNewChart.destroy() if @myNewChart

      dataPresent = $("#totals-data-block").length > 0
      # if we select tip outs for all areas, given and received areas will always be the same.
      uselessDataPresent = (type is "tip-outs-cc" or type is "tip-outs-cash") && $("select#area_type_id").val().toLowerCase() == "all"
      $("#area-colors").html("")

      if dataPresent && !uselessDataPresent
        labels = _.map( $("#totals-data-block thead tr.dates th.date"), (e) -> return $(e).text() )
        data = $("#totals-data-block tbody tr.total-#{ type }-tips td.data .#{ type }")

        if type is "tip-outs-cc" or type is "tip-outs-cash"
          data = [
            {
                label: "Example dataset",
                fillColor: "rgba(98,203,49,0.5)",
                strokeColor: "rgba(98,203,49,0.7)",
                pointColor: "rgba(98,203,49,1)",
                pointStrokeColor: "#fff",
                pointHighlightFill: "#fff",
                pointHighlightStroke: "rgba(98,203,49,1)",
                data: _.map( data, (e) -> return parseFloat( Math.abs( $(e).find(".received").text() )))
            },
            {
                label: "Example dataset",
                fillColor: "rgba(255, 128, 0, 0.5)",
                strokeColor: "rgba(255, 128, 0, 0.7)",
                pointColor: "rgba(255, 128, 0, 1)",
                pointStrokeColor: "#fff",
                pointHighlightFill: "#fff",
                pointHighlightStroke: "rgba(26,179,148,1)",
                data: _.map( data, (e) -> return parseFloat( Math.abs( $(e).find(".given").text() )))
            }
          ]
        else
          data = []
          areas = _.map($("#totals-data-block tbody tr.area-totals"), (e) -> return $(e).attr("data-area-name").toLowerCase() )
          areas = _.uniq(areas)
          text = ""

          _.each areas, (e) ->
            color = gon.area_colors[e]
            text += "<div class='area-label' style='color:" + color + ";'><span class='area-sign' style='background-color:" + color + ";'></span>" + e + "</div>"

            data.push({
              fillColor: color,
              strokeColor: color,
              highlightFill: color,
              highlightStroke: color,
              data: _.map($("#totals-data-block tbody tr[data-area-name='" + e + "'].area-totals.total-" + type + "-tips td.area-data ." + type), (e) -> return parseFloat($(e).text()) )
            })

          $("#area-colors").html(text)


        sharpLineData = {
          labels: labels,
          datasets: data
        }

        sharpLineOptions = {
            scaleBeginAtZero : true,
            scaleShowGridLines : true,
            scaleGridLineColor : "rgba(0,0,0,.05)",
            scaleGridLineWidth : 1,
            barShowStroke : true,
            barStrokeWidth : 1,
            barValueSpacing : 5,
            barDatasetSpacing : 1,
            responsive:true,
            maintainAspectRatio: false
        }

        ctx = document.getElementById("singleBarOptions").getContext("2d")
        @myNewChart = new Chart(ctx).Bar(sharpLineData, sharpLineOptions)
    )

  $(document).ready ->
    if $("body").hasClass("reports")
      Tipcalc.Controllers.reportsView = new ReportsView()
)()
