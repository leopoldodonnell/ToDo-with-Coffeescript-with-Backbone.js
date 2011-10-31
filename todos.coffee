# A literal Coffescript translation of the example Backbone application contributed by
# [JÃ©rÃ´me Gravel-Niquet](http://jgn.me/). This demo uses a simple
# [LocalStorage adapter](backbone-localstorage.html)
# to persist Backbone models within your browser.
#
# Coffeescript translation by Leopold O'Donnell

jQuery ->
	# Todo
	class window.Todo extends Backbone.Model
		defaults: ->
			done: false
			order: Todos.nextOrder()
		
		toggle: -> @save	{done: !this.get("done")}

	###
	 Todo Collection
	 ---------------

	 The collection of todos is backed by *localStorage* instead of a remote
	 server.
	###
	class TodoList extends Backbone.Collection
		# Reference to this collection's model.
		model: Todo
	
		# Save all of the todo items uner the `"todos"` namespace.
		localStorage: new Store "todos"
	
		# Filter down the list of all todo items that are finished.
		done: -> @filter( (todo) -> todo.get 'done' )
	
		# Filter down the list to only todo items that are still not finished
		remaining: -> @without.apply @, @done()
	
		# We keep the Todos in sequention order, depsonte being saved by unordered
		# GUID in the database. This generates the next order number for new items.
		nextOrder: -> if @length == 0 then 1 else @last().get('order') + 1

		# Todos are sorted by thier original insertion order.
		comparitor: (todo) -> todo.get 'order'
	
	# Create our global collection of **Todos**
	Todos = new TodoList

	###
		Todo Item View
		--------------
	
		The DOM element for a todo item...
	###
	class TodoView extends Backbone.View
		#... is a list tag.
		tagName: "li"
	
		# Cache the template function for a single item
		template: _.template $('#item-template').html()
	
		# The DOM events specific to an item.
		events:
			"click .check"						: "toggleDone"
			"dblclick div.todo-text"	: "edit"
			"click span.todo-destroy"	: "clear"
			"keypress .todo-input"		: "updateOnEnter"
	
		# The TodoView listens for changes to its model, re-rendering
		initialize: ->
			@model.bind 'change', @render, @
			@model.bind	'destroy', @remove, @
			@model.view = @
		
		# Re-render the contents of the todo item.
		render: ->
			$(@el).html @template @model.toJSON()
			@setText()
			@

		# To avoid XSS (not that it would be harmful in this particular app),
		# we use `jQuery.text` to set the contents of the todo item.
		setText: ->
			text = @model.get 'text'
			@$('.todo-text').text text
			@input = @$('.todo-input')
			@input.bind('blur', _.bind @close, @).val text

		# Toggle the `"done"` state of the model.
		toggleDone: -> @model.toggle()
	
		# Switch the view into `"editing"` mode, displaying the input field.
		edit: ->
			$(@el).addClass "editing"
			@input.focus()
	
		# Clost the `"editing"` mode, saving the changes to the todo
		close: ->
			@model.save text: @input.val()
			$(@el).removeClass "editing"

		# If you hit `enter`, we're through editing the item.
		updateOnEnter: (e) -> @close() if e.keyCode == 13
	
		# Remove the view from the DOM.
		remove: -> $(@el).remove()
	
		# Remove the item, destroy the model.
		clear: -> @model.destroy()

	###
		The Application
		---------------
	
		Our overall **AppView** is the top-level piece of UI
	###
	class AppView extends Backbone.View
		# Instead of generating a new element, bind to the existing skeleton of
		# the App already present in the HTML.
		el: $("#todoapp")
	
		# Out template for the line of statistics at the bottom of the app.
		statsTemplate: _.template $('#stats-template').html()
	
		# Delegated events for creating new items, and clearing completed ones.
		events:
			"keypress #new-todo":		"createOnEnter"
			"keyup #new-todo":			"showTooltip" 
			"click .todo-clear a":	"clearCompleted"
	
		# At initialization we bind to the relevant events on the `Todos`
		# collection, when items are added or changed. Kick things off by
		# loading any preexisting todos that might be saved in *localStorage*.
		initialize: ->
			@input = @$("#new-todo")
		
			Todos.bind 'add', @addOne, @
			Todos.bind 'reset', @addAll, @
			Todos.bind 'all', @render, @
		
			Todos.fetch()
	
		# Re-rendering the App just means refreshing the statistics -- the rest
		# of the app doesn't change.
		render: ->
			@$('#todo-stats').html @statsTemplate
				total: 			Todos.length
				done:				Todos.done().length
				remaining:	Todos.remaining().length
	
		# Add a single todo item to the list by creating a view for it, and
		# appending its element to the `<ul>`.
		addOne: (todo) ->
			view = new TodoView model: todo
			@$("#todo-list").append view.render().el
	
		# Add all items in the **Todos** collection at once.
		addAll: -> Todos.each @addOne
	
		# If you hit return in the main input field, and there is text to save,
		# create new **Todo** model persisting it to *localStorage*
		createOnEnter: (e) ->
			text = @input.val()
			return if !text || e.keyCode !=13
			Todos.create text: text
			@input.val('')
		
		# Clear all done todo items, destroying their models.
		clearCompleted: -> 
			_.each Todos.done(), (todo) -> todo.destroy()
			false
	
		# Lazily show the tooltip that tells you to press `enter` to save
		# a new todo item, after one second.
		showTooltip: (e) ->
			tooltip = @$(".ui-tooltip-top")
			val = @input.val()
			tooltip.fadeOut()
			clearTimeout @tooltipTimeout if @tooltipTimeout
			return if val == '' || val == @input.attr('placeholder')
			show = -> tooltip.show().fadeIn()
			@tooltipTimeout = _.delay show, 1000

	
	# Finally, we kick things off by creating the **App**.
	#window.App = new AppView

	App = new AppView