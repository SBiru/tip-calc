@Tipcalc ||= {}
@Tipcalc.Controllers ||= {}
@Tipcalc.Modules ||= {}

@Tipcalc.Controllers.notifier = {
  alert: (title, message, buttonText, showCancel, callback) ->
    options = {
      title: title,
      text: message,
      type: "error",
      confirmButtonColor: "#BB473E",
      confirmButtonText: buttonText || "Ok"
    }

    if showCancel
      options = _.extend options, {
        showCancelButton: true,
        cancelButtonText: "Cancel"
      }

    swal(
      options
    , (isConfirm) =>
      callback() if callback and isConfirm
      true
    )
  info: (title, message, buttonText, showCancel, callback) ->
    options = {
      title: title,
      text: message,
      type: "info",
      confirmButtonColor: "#28C256",
      confirmButtonText: buttonText || "Ok"
    }

    if showCancel
      options = _.extend options, {
        showCancelButton: true,
        cancelButtonText: "Cancel"
      }

    swal(
      options
    , (isConfirm) =>
      callback() if callback and isConfirm
      true
    )
}