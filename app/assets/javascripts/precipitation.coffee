# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'page:change', ->
  params = document.URL.extract()

  if (not params or not params['location']) and navigator.geolocation
    navigator.geolocation.getCurrentPosition(locateSuccess, locateError)

locateSuccess = (position) ->
  lat = position.coords.latitude
  lon = position.coords.longitude
  window.location = '?location=' + lat + ',' + lon

locateError = (error) ->