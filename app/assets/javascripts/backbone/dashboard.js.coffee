(->
  DashboardView = Backbone.View.extend(
    el: "body.dashboard"
    events:
      "click .toggle-collapse": "toggleCollapse"
      "click .top-header button": "switchDateRange"
      "ifChanged #top_employees_is_shown": "topEmployeesIsShownToggle"

    initialize: ->
      @initDataTables()
      @selectDate()

    topEmployeesIsShownToggle: (e) ->
      $.ajax
        url: "api/restaurants/1" #TODO
        method: "put"
        id: "1"
        data:
          restaurant:
            top_employees_is_shown: e.currentTarget.checked
        success: =>
          console.log "+"
        error: ->
          console.log "-"

    switchDateRange: (e) ->
      $(".top-header button").removeClass("active")
      range = $(e.currentTarget).attr("data-date-range")
      $(e.currentTarget).addClass("active")
      $("#top-employees .data-range-type").attr("data-date-range", range)
      for td in $("#top-employees .data-range-type")
        data = $(td).find("div.#{ range }").text().replace("$", "")
        $(td).attr("data-sort", data)

      table = $("#top-employees").DataTable()
      table.cells(".data-range-type").invalidate().draw()

    initDataTables: ->
      $("#top-employees").dataTable( {
        "order": [],
        "bInfo": false,
        "paging": false,
        "searching": false,
        "columnDefs": [ {
          "targets"  : 'no-sort',
          "orderable": false
        }]
      });

      $('#top-employees').on 'draw.dt', ->
        i = 1
        for tr in $("#top-employees tbody tr")
          $(tr).find("td:first-child").text(i)
          i += 1

    selectDate: ->
      $('.datapicker').datepicker({
        weekStart: 1,
        disableTouchKeyboard: true,
      })

    toggleCollapse: (e) ->
      e.preventDefault()
      $("#top-employees").toggleClass("collapsed")
      $(e.currentTarget).toggleClass("collapsed")
  )

  $(document).ready ->
    if $("body").hasClass("dashboard")
      Tipcalc.Controllers.dashboardView = new DashboardView()
)()
