{CompositeDisposable, Point} = require 'atom'
{$, ScrollView} = require 'atom-space-pen-views'

module.exports =
class FountainSceneListView extends ScrollView
  panel: null

  initialize: (state) ->
    super
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.workspace.onDidChangeActivePaneItem(@changedPane)

    @editorSubs = new CompositeDisposable

    @attach()

  attach: ->
    @panel ?= atom.workspace.addRightPanel {
      item: this
      visible: false
    }

  @content: ->
    @div class: 'fountain-scene-list', tabindex: -1, =>
      @div class: 'panel-heading', "Fountain Scene List"
      @div class: 'panel-body padded', =>
        @ul class: 'list-group', outlet: "list"

  serialize: ->

  destroy: ->
    @subscriptions.dispose()
    @editorSubs.dispose()
    @element.remove()

  updateList: =>
    text = @editor.getText()
    scenes = @findScenes(text)

    @list.empty()

    for scene in scenes
      $('<li data-line="'+ scene.line + '"></li>')
        .append('<span class="icon icon-book">' + scene.title + '</span>')
        .addClass('list-item')
        .appendTo(@list)
        .on 'click', (e) =>
          line = parseInt($(e.currentTarget).attr('data-line'))

          position = new Point(line, -1)
          @editor.scrollToBufferPosition(position)
          @editor.setCursorBufferPosition(position)
          @editor.moveToFirstCharacterOfLine()

  findScenes: (text) ->
    scenes = []

    currentScene =
      line:     0
      title:    'TOP'
      hasNote:  false

    for line, index in text.split('\n')
      if line.match(/^(EXT)|(INT)|(\^.[A-Z]+)/)
        scenes.push currentScene

        currentScene =
          line: index
          title: line
          hasNote: false

      if line.match(/\[\[[^\]]*\]\]/)
        currentScene.hasNote = true

    scenes.push(currentScene)
    scenes

  clearScenes: (text) ->
    @list.innerHTML = ""

  changedPane: (pane) =>
    @editorSubs.dispose()

    if pane and (typeof pane.getText == 'function')
      @editor = pane
      @editorSubs.add @editor.onDidStopChanging(@updateList)
      @updateList()
    else
      @clearScenes()
