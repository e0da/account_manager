form = null
new_password = null
validation = false
flash = null

error = (msg) ->
  flash = $('.flash.error')
  if flash.length == 0
    flash = $('<div id=flash><ul class="flash error"></ul></div>').find('.flash.error') if flash.length == 0
    $('#help').append flash
  flash.append $("<li>#{msg}</li>")
  $('#problems').show()
  $(window).resize() # in case the size of the container changed

validate_form = ->

  flash.remove() if flash
  $('#problems').hide()

  valid = true
  if $(':text[value=""], :password[value=""]').length > 0
    valid = false
    error 'You must fill every field.'
  if $('#agree').length == 1 and $('#agree:checked').length == 0
    valid = false
    error 'You must agree to the terms and conditions.'
  if $('#new_password').val() != $('#verify_password').val()
    valid = false
    error 'Your new passwords do not match.'
  if new_password.length > 0 and !new_password.data('strong')
    valid = false
    error 'Your new password is too weak.'

  form.data('valid', valid)

$ ->
  $('#problems').hide()
  $('#nav ul ul').hide()
  $('#nav .more').text('...').click ->
    $('#nav ul ul').toggle()

  form = $('form')
  new_password = $('#new_password')
  form.submit (e) ->
    validation = true
    validate_form()
    if form.data 'valid'
      form.submit()
    else
      e.preventDefault()

  form.bind 'keyup mouseup', (e) ->
    validate_form() if validation

  # handle this separately
  $('#agree').click ->
    validation = true
    validate_form()

  new_password.keyup (e) ->
    $.post 'password_strength', {password: new_password.val()}, (strong) ->
      strong = parseInt(strong)
      desc = if strong then 'strong!' else 'weak :('
      color = if strong then '#4FB32B' else '#f00'
      $('#password_feedback').text(desc).css(color: color)
      new_password.data 'strong', (if strong then true else false)

  # keep #help and the form the same height
  $(window).resize ->
    max = 0
    $('form, #help').each ->
      max = Math.max max, $(this).height()
    $('form, #help').height max

  $(window).resize()
