form = null
new_password = null
validation = false
flash = null

enable = (el) ->
  el.removeClass('disabled').attr('disabled', null)

disable = (el) ->
  el.addClass('disabled').attr('disabled', 'disabled')

error = (msg) ->
  flash = $('#help .flash.error')
  console.log flash
  if flash.length == 0
    flash = $('<div id=js_flash><ul class="flash error"></ul></div>').find('.flash.error') if flash.length == 0
    $('#help').append flash
  flash.append $("<li>#{msg}</li>")
  $('#problems').show()
  $(window).resize() # in case the size of the container changed

sanitize_form = ->
  $('input[type=text]').each ->
    $(this).val $(this).val().trim()
  $('#uid').val $('#uid').val().replace /@.*/, ''


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

check_password = (e) ->
  @xhr.abort() if @xhr
  @xhr = $.post 'password_strength', {password: new_password.val()}, (strong) ->
    strong = parseInt(strong)
    desc = if strong then 'strong!' else 'weak :('
    color = if strong then '#080' else '#f00'
    $('#password_feedback').text(desc).css(color: color)
    new_password.data 'strong', (if strong then true else false)

$ ->
  $('#problems').hide()
  $('#nav ul ul').hide()
  $('#nav .more').text('...').click ->
    $('#nav ul ul').toggle()

  form = $('form')
  button = $('button')
  new_password = $('#new_password')
  form.submit (e) ->
    disable form
    disable button
    validation = true
    sanitize_form()
    validate_form()
    unless form.data 'valid'
      e.preventDefault()
      enable form
      enable button

  form.bind 'keyup mouseup', (e) ->
    validate_form() if validation

  # handle this separately
  $('#agree').click ->
    validation = true
    validate_form()

  new_password.bind 'keyup mouseup', check_password

  # keep #help and the form the same height
  $(window).resize ->
    max = 0
    $('form, #help').each ->
      $(this).height 'auto'
      max = Math.max max, $(this).height()
    $('form, #help').height max

  $(window).resize()

  # autofocus on first input on page
  $('input:first').focus()
