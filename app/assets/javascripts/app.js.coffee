@Tipcalc ||= {}
@Tipcalc.Controllers ||= {}
@Tipcalc.Modules ||= {}

(->
  $.fn.editAndFocus = (e) ->
    this.attr("contenteditable", e)
    if e is true
      this.removeAttr("disabled")
      this.focus()
    else
      this.attr("disabled", !e)
      this.blur()

  $.fn.saveData = ->
    for el in $(this)
      $(el).attr("data-original-value", $(el).val())
    this

  $.fn.restoreData = (field) ->
    for el in $(this)
      $(el).val($(el).attr("data-original-value"))
    this.clearCashedData()

  $.fn.clearCashedData = (field) ->
    for el in $(this)
      $(el).removeAttr("data-original-value")
    this

  toastr.options = {
    "closeButton": true,
    "debug": false,
    "newestOnTop": false,
    "progressBar": false,
    "positionClass": "toast-top-center",
    "preventDuplicates": false,
    "onclick": null,
    "showDuration": "300",
    "hideDuration": "1000",
    "timeOut": "3000",
    "extendedTimeOut": "1000",
    "showEasing": "swing",
    "hideEasing": "linear",
    "showMethod": "fadeIn",
    "hideMethod": "fadeOut"
  } 
)()