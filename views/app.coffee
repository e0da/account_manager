complain = (msg) ->
  flash 'error', msg

flash = (type, msg) ->
  list = $('#flash ul')
  if list.length == 0
    list = $("<ul class=\"flash #{type}\">")
    div = $('<div id=flash>')
    div.append(list)
    $('.content').prepend(div)

  list.append $("<li>#{msg}</li>")

remove_flash = ->
  $('#flash').remove()

check_password_strength = ->
  $.getJSON "password_strength/#{$('#new_password').val()}", (data) ->
    form = $('form')
    if data == 1 then form.trigger 'weak_password' else form.trigger 'strong_password'

blanks = ->
  has_blanks = false
  has_blanks = true for f in $('input:text[value=""], input:password[value=""]')
  has_blanks

validate_form = ->
  remove_flash()
  form = $('form')
  form.trigger 'blank_fields' if blanks()
  form.trigger 'agree_not_checked' if $('#agree:checked').length == 0
  form.trigger 'password_mismatch' if $('#new_password').val() != $('#verify_password').val()
  check_password_strength()
  form.submit() unless $('#flash').length > 0

bind_form_validations = ->

  $('form').bind 'blank_fields', (e) ->
    complain 'All fields are required'

  $('form').bind 'agree_not_checked', (e) ->
    complain 'You must agree to the terms and conditions'

  $('form').bind 'password_mismatch', (e) ->
    complain 'Your new passwords do not match'

  $('form').bind 'weak_password', (e) ->
    complain 'Your new password is too weak'

  $('form').bind 'strong_password', (e) ->
    

  $('button[type=submit]').attr('disabled', 'disabled').click (e) ->
    e.preventDefault()
    validate_form()

hide_admin_in_nav = ->
  $('.nav ul ul').hide()
  $('.nav .more').text('...').click ->
    $('.nav ul ul').toggle()

$ ->
  hide_admin_in_nav()
  bind_form_validations()
