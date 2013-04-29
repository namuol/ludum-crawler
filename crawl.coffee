Crawler = require('crawler').Crawler
beautify = require('js-beautify').js_beautify

config = require './config'

dump =
  format_version: '0.0.1'
  base_url: config.base_url
  dump_date: (new Date()).toISOString()
  games: []

mainThumbs = {}

getImageFilename = (url) -> url.split(config.base_img_url)[1]

getThumbFilename = (url) -> url.split(config.base_img_thumb_url)[1]

gameDataCollector = new Crawler
  maxConnections: config.max_connections,
  callback: (err, result, $) ->
    if err
      console.error err
      return

    game = {}

    # TITLE / AUTHOR/ TYPE ##################

    [ game.title
      game.author
      typeText ] = $('h3').first().text().split(' - ')

    if typeText is '48 Hour Compo Entry'
      game.type = 48
    else
      game.type = 72

    # UID ####################################
    
    game.uid = result.window.location.href.split('uid=')[1]
    
    # LINKS ##################################

    game.links = []
    for a in $('.links > a')
      link =
        type: a.textContent
        href: a.href
      game.links.push link

    # SCREENSHOTS ############################

    mainShotLink = $('#compo2 > table tr:first a')[0]
    mainShot =
      src: getImageFilename mainShotLink.href
      thumb: mainThumbs[game.uid]
      bigThumb: getThumbFilename $(mainShotLink).children('img')[0].src
    
    game.shots = [mainShot]
    
    # slice(1) skips the first TR since it contained
    #  the main screenshot.
    for a in $('#compo2 > table tr').slice(1).find('a')
      shot =
        src: getImageFilename a.href
        thumb: getThumbFilename $(a).children('img')[0].src
      game.shots.push shot

    dump.games.push game
    console.error beautify JSON.stringify(game),
      indent_size: 2

  onDrain: ->
    console.log JSON.stringify dump

gameLinkCollector = new Crawler
  maxConnections: 1,
  callback: (err, result, $) ->
    if err
      console.error err
      return
    for a in $("#compo2 > .preview a")
      gameDataCollector.queue a.href
      uid = a.href.split('uid=')[1]
      thumbSrc = $(a).children('img')[0].src
      mainThumbs[uid] = getThumbFilename thumbSrc

start = new Crawler
  maxConnections: 1,
  callback: (err, result, $) ->
    if err
      console.error err
      return

    pages = $("#compo2 > .preview").first().next('p').children('a')
    for page in pages
      gameLinkCollector.queue page.href

start_url = config.base_url + '?action=preview'

#gameDataCollector.queue 'http://www.ludumdare.com/compo/ludum-dare-26/?action=preview&uid=1712'

start.queue start_url