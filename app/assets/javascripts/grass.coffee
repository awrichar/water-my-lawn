canvas = null
blades = null
curWidth = 0
lastUpdate = new Date().getTime()

green =
  r: 0
  g: 128
  b: 0

brown =
  r: 222
  g: 184
  b: 135

averageColor = (c1, c2, t) ->
  if t < 0
    t = 0
  else if t > 1
    t = 1

  return {
    r: parseInt(c1['r'] + (c2['r'] - c1['r']) * t)
    g: parseInt(c1['g'] + (c2['g'] - c1['g']) * t)
    b: parseInt(c1['b'] + (c2['b'] - c1['b']) * t)
  }

randRange = (min, max) ->
  range = max - min
  return Math.floor((Math.random() * range) + min)

maybeNegative = (x) ->
  return if Math.random() > .5 then x else -x

makeBlade = (centerX) ->
  topY = randRange 0, 15
  bottomY = 200
  middleY = (topY + bottomY) / 2

  width = randRange 20, 40
  halfWidth = width / 2
  curve = maybeNegative randRange(width / 3, width * 2 / 3)

  leftX = centerX - halfWidth
  leftCurveX = leftX + curve
  rightX = leftX + width
  rightCurveX = rightX + curve

  startX = randRange leftX, rightX
  colorVariance = maybeNegative Math.random() * .25
  color = averageColor brown, green, (window.saturation + colorVariance)

  path = new fabric.Path 'M ' + leftX + ' ' + bottomY + ' ' +
                         'Q ' + leftCurveX + ' ' + middleY + ' ' + startX + ' ' + topY + ' ' +
                         'Q ' + rightCurveX + ' ' + middleY + ' ' + rightX + ' ' + bottomY + ' z'
  path.set
    fill: 'rgb(' + color['r'] + ',' + color['g'] + ',' + color['b'] + ')'
    selectable: false

  return {
    path: path,
    left: centerX - width / 3
    right: centerX + width / 3
    speed: (maybeNegative randRange 1, 5) / 1000
  }

$(document).on 'page:change', ->
  canvas = new fabric.Canvas 'canvas'
  renderCanvas()
  requestAnimationFrame ->
    updatePaths()

$(window).resize ->
  renderCanvas()

renderCanvas = ->
  width = $(window).width()
  if curWidth != width
    curWidth = width
    canvas.clear()
    canvas.setWidth(width);

    numBlades = width / 10
    blades = []

    for i in [1..numBlades]
      blade = makeBlade(randRange 0, width)
      blades.push blade
      canvas.add blade.path

updatePaths = ->
  now = new Date().getTime()
  elapsed = now - lastUpdate;
  lastUpdate = now

  for blade in blades
    x = blade.path.path[1][3] + blade.speed * elapsed
    if x >= blade.right
      x = blade.right
      blade.speed *= -1
    else if x <= blade.left
      x = blade.left
      blade.speed *= -1
    blade.path.path[1][3] = x

  canvas.renderAll()
  requestAnimationFrame ->
    updatePaths()