# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

field = null;

$(document).on 'page:change', ->
  params = document.URL.extract()

  if (not params or not params['location']) and navigator.geolocation
    navigator.geolocation.getCurrentPosition(locateSuccess, locateError)

  field = new grassyField 'canvas'
  field.resizeCanvas $(window).width(), 200

$(window).resize ->
  field.resizeCanvas $(window).width(), 200

locateSuccess = (position) ->
  lat = position.coords.latitude
  lon = position.coords.longitude
  window.location = '?location=' + lat + ',' + lon

locateError = (error) ->