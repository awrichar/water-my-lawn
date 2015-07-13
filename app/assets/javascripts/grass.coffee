speed = 5 / 1000

sizeCanvas = ->
  canvas = document.getElementById 'canvas'
  canvas.width = $(window).width()

randRange = (min, max) ->
  range = max - min
  return Math.floor((Math.random() * range) + min)

makeBlade = (centerX) ->
  topY = 0
  bottomY = 200
  middleY = (topY + bottomY) / 2

  width = randRange 20, 40
  halfWidth = width / 2
  curve = randRange(width / 3, width * 2 / 3)
  curve *= -1 if Math.random() > .5

  leftX = centerX - halfWidth
  leftCurveX = leftX + curve
  rightX = leftX + width
  rightCurveX = rightX + curve

  startX = randRange leftX, rightX

  path = new fabric.Path 'M ' + leftX + ' ' + bottomY + ' ' +
                         'Q ' + leftCurveX + ' ' + middleY + ' ' + startX + ' ' + topY + ' ' +
                         'Q ' + rightCurveX + ' ' + middleY + ' ' + rightX + ' ' + bottomY + ' z'
  path.set
    fill: 'rgb(0,' + randRange(100, 160) + ',0)'
    selectable: false

  return {
    path: path,
    left: centerX - width / 3,
    right: centerX + width / 3,
    dir: (Math.random() > .5) ? 1 : -1
  }

$(window).resize ->
  sizeCanvas()

$(document).on 'page:change', ->
  sizeCanvas()

  canvas = new fabric.Canvas 'canvas'
  lastUpdate = new Date().getTime()

  canvasWidth = $('#canvas').width()
  numBlades = canvasWidth / 10
  blades = []

  for i in [1..numBlades]
    blade = makeBlade(randRange 0, canvasWidth)
    blades.push blade
    canvas.add blade.path

  updatePath = ->
    now = new Date().getTime()
    elapsed = now - lastUpdate;
    lastUpdate = now

    for blade in blades
      x = blade.path.path[1][3] + blade.dir * speed * elapsed
      if x >= blade.right
        x = blade.right
        blade.dir *= -1
      if x <= blade.left
        x = blade.left
        blade.dir *= -1
      blade.path.path[1][3] = x

    canvas.renderAll()
    requestAnimationFrame ->
      updatePath()

  updatePath()