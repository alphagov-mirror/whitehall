module('Document filter', {
  setup: function () {
    this.originalHistoryEnabled = window.GOVUK.support.history
    this.originalHistoryPushState = history.pushState
    history.pushState = function (state, title, url) {
      return true
    }

    this.filterForm = $('<form id="document-filter" action="/foo/bar">' +
      '<input type="submit" />' +
      '<select id="departments" multiple="multiple">' +
      '<option value="all" selected="selected">All</option>' +
      '<option value="dept1">Dept1</option>' +
      '<option value="dept2">Dept2</option>' +
      '</select>' +
      '<input type="radio" id="direction_before">' +
      '<input type="radio" id="direction_after" value="after" checked="checked"> ' +
      '<input type="text" id="keywords" value=""> ' +
      '</form>')
    $('#qunit-fixture').append(this.filterForm)

    this.filterResults = $('<div class="js-filter-results" />')
    $('#qunit-fixture').append(this.filterResults)

    this.feedLinks = $('<div class="feeds"><a class="feed">feed</a> <a class="email-signup">email</a></div>')
    $('#qunit-fixture').append(this.feedLinks)

    this.resultsSummary = $('<div class="filter-results-summary"></div>')
    $('#qunit-fixture').append(this.resultsSummary)

    this.ajaxData = {
      'next_page?': true,
      next_page: 2,
      next_page_url: '/next-page-url',
      next_page_web_url: '/next-page-url',

      prev_page_url: '/prev-page-url',
      prev_page_web_url: '/prev-page-url',
      'more_pages?': true,
      total_pages: 5,

      atom_feed_url: '/atom-feed',
      email_signup_url: '/email-signups',
      'results_any?': true,
      total_count: 8,
      result_type: 'publication',
      results: [
        {
          result: {
            id: 1,
            type: 'document-type',
            title: 'document-title',
            url: '/document-path',
            organisations: 'organisation-name-1, organisation-name-2',
            topics: 'topic-name-1, topic-name-2',
            field_of_operation: 'place-of-war'
          },
          index: 1
        },
        {
          result: {
            id: 2,
            type: 'document-type-2',
            title: 'document-title-2',
            url: '/document-path-2',
            organisations: 'organisation-name-2, organisation-name-3',
            publication_collections: 'collection-1'
          },
          index: 2
        }
      ]
    }
  },
  tearDown: function () {
    window.GOVUK.support.history = this.originalHistoryEnabled
    history.pushState = this.originalHistoryPushState
  }
})

test('should render mustache template from ajax data', sinon.test(function () {
  var stub = this.stub($.fn, 'mustache')
  stub.returns(true)

  GOVUK.documentFilter.renderTable(this.ajaxData)

  equal(stub.getCall(0).args[1], this.ajaxData)
}))

test('should show message when ajax data is empty', function () {
  GOVUK.documentFilter.renderTable({ 'results_any?': false })

  equal(this.filterResults.find('js-document-list').length, 0)
  equal(this.filterResults.find('.no-results').length, 1)
})

test('should update the atom feed url', function () {
  equal(this.feedLinks.find('a[href="/atom-feed"]').length, 0)

  GOVUK.documentFilter.updateAtomFeed(this.ajaxData)

  equal(this.feedLinks.find('a[href="/atom-feed"]').length, 1)
})

test('should update the email signup url', function () {
  equal(this.feedLinks.find('a[href="/email-signups"]').length, 0)

  GOVUK.documentFilter.updateEmailSignup(this.ajaxData)

  equal(this.feedLinks.find('a[href="/email-signups"]').length, 1)
})

test('should make an ajax request on form submission to obtain filtered results', sinon.test(function () {
  this.filterForm.enableDocumentFilter()

  var ajax = this.spy(jQuery, 'ajax')
  var server = this.sandbox.useFakeServer()

  this.filterForm.submit()
  server.respond()

  sinon.assert.calledOnce(ajax)
}))

test('should send ajax request using json form of url in form action', sinon.test(function () {
  this.filterForm.enableDocumentFilter()

  this.spy(jQuery, 'ajax')
  var server = this.sandbox.useFakeServer()

  $(this.filterForm).attr('action', '/specialist')

  this.filterForm.submit()
  server.respond()

  var url = jQuery.ajax.getCall(0).args[0]
  equal(url, '/specialist.json')
}))

test('should send filter form parameters in ajax request', sinon.test(function () {
  this.filterForm.enableDocumentFilter()

  this.spy(jQuery, 'ajax')
  var server = this.sandbox.useFakeServer()

  $(this.filterForm).append($('<select name="foo"><option value="bar" /></select>'))

  this.filterForm.submit()
  server.respond()

  var settings = jQuery.ajax.getCall(0).args[1]
  equal(settings.data[0].name, 'foo')
  equal(settings.data[0].value, 'bar')
}))

test('should render results based on successful ajax response', sinon.test(function () {
  this.filterForm.enableDocumentFilter()
  GOVUK.analytics = { trackPageview: function () {} }

  var server = this.sandbox.useFakeServer()
  server.respondWith(JSON.stringify(this.ajaxData))

  this.filterForm.submit()
  server.respond()

  equal(this.filterResults.find('.document-row').length, 2)
  equal(this.filterResults.find('.document-row .document-collections').text(), 'collection-1')
  equal(this.filterResults.find('.document-row .topics').text(), 'topic-name-1, topic-name-2')
  equal(this.filterResults.find('.document-row .field-of-operation').text(), 'place-of-war')
}))

test('should fire analytics on successful ajax response', sinon.test(function () {
  this.filterForm.enableDocumentFilter()
  GOVUK.analytics = { trackPageview: function () {} }

  var analytics = this.spy(GOVUK.analytics, 'trackPageview')
  var server = this.sandbox.useFakeServer()
  server.respondWith(JSON.stringify(this.ajaxData))

  this.filterForm.submit()
  server.respond()

  sinon.assert.callCount(analytics, 1)
}))

test('should apply hide class to feed on ajax call', sinon.test(function () {
  this.filterForm.enableDocumentFilter()

  var server = this.sandbox.useFakeServer()
  server.respondWith(JSON.stringify(this.ajaxData))

  this.filterForm.submit()
  ok(this.feedLinks.is('.js-hidden'))
  server.respond()
  ok(!this.feedLinks.is('.js-hidden'))
}))

test('currentPageState should include the current results', function () {
  this.filterForm.enableDocumentFilter()
  var resultsContent = '<p>Test content</p>'
  this.filterResults.html(resultsContent)
  equal(GOVUK.documentFilter.currentPageState().html, resultsContent)
})

test('currentPageState should include the state of any select boxes', function () {
  this.filterForm.enableDocumentFilter()
  deepEqual(GOVUK.documentFilter.currentPageState().selected, [{ id: 'departments', value: ['all'], title: ['All'] }])
})

test('currentPageState should include the state of any radio buttons', function () {
  this.filterForm.enableDocumentFilter()
  deepEqual(GOVUK.documentFilter.currentPageState().checked, [{ id: 'direction_after', value: 'after' }])
})

test('currentPageState should include the state of any text inputs', function () {
  this.filterForm.enableDocumentFilter()
  var searchText = 'my example search'
  this.filterForm.find('#keywords').val(searchText)
  deepEqual(GOVUK.documentFilter.currentPageState().text, [{ id: 'keywords', value: searchText }])
})

test('onPopState should restore the state as specified in the event', function () {
  this.filterForm.enableDocumentFilter()
  var event = {
    state: {
      html: '<p>Old content</p>',
      selected: [{ id: 'departments', value: ['dept1'] }],
      text: [{ id: 'keywords', value: ['some search'] }],
      checked: ['direction_before']
    }
  }
  GOVUK.documentFilter.onPopState(event)
  equal(this.filterResults.html(), event.state.html, 'filter results updated to previous value')
  deepEqual(this.filterForm.find('#departments').val(), ['dept1'], 'old department selected')
  equal(this.filterForm.find('#keywords').val(), 'some search', 'filter results updated to previous value')
  ok(this.filterForm.find('#direction_before:checked'), "date 'before' radio checked")
})

test('should record initial page state in browser history', sinon.test(function () {
  var oldPageState = window.GOVUK.documentFilter.currentPageState
  window.GOVUK.documentFilter.currentPageState = function () { return 'INITIALSTATE' }

  var historyReplaceState = this.spy(history, 'replaceState')
  this.filterForm.enableDocumentFilter()

  var data = historyReplaceState.getCall(0).args[0]
  equal(data, 'INITIALSTATE', 'Initial state is stored in history data')

  window.GOVUK.documentFilter.currentPageState = oldPageState
}))

test('should update browser location on successful ajax response', sinon.test(function () {
  this.filterForm.enableDocumentFilter()

  var oldPageState = window.GOVUK.documentFilter.currentPageState
  window.GOVUK.documentFilter.currentPageState = function () { return 'CURRENTSTATE' }

  var historyPushState = this.spy(history, 'pushState')
  var server = this.sandbox.useFakeServer()
  server.respondWith(JSON.stringify(this.ajaxData))

  $(this.filterForm).attr('action', '/specialist')
  $(this.filterForm).append($('<select name="foo"><option value="bar" /></select>'))

  this.filterForm.submit()
  server.respond()

  var data = historyPushState.getCall(0).args[0]
  equal(data, 'CURRENTSTATE', 'Current state is stored in history data')

  var title = historyPushState.getCall(0).args[1]
  equal(title, null, 'Setting this to null means title stays the same')

  var path = historyPushState.getCall(0).args[2]
  equal(path, '/specialist?foo=bar', 'Bookmarkable URL path')

  window.GOVUK.documentFilter.currentPageState = oldPageState
}))

test('should store new table html on successful ajax response', sinon.test(function () {
  this.filterForm.enableDocumentFilter()

  var historyPushState = this.spy(history, 'pushState')
  var server = this.sandbox.useFakeServer()
  server.respondWith(JSON.stringify(this.ajaxData))

  this.filterForm.submit()
  server.respond()

  var data = historyPushState.getCall(0).args[0]
  ok(!!data.html.match('document-title'), 'Current state is stored in history data')
}))

test('should not enable ajax filtering if browser does not support HTML5 History API', sinon.test(function () {
  var oldHistory = window.GOVUK.support.history
  window.GOVUK.support.history = function () { return false }

  this.filterForm.enableDocumentFilter()

  var ajax = this.spy(jQuery, 'ajax')
  var server = this.sandbox.useFakeServer()

  this.filterForm.attr('action', 'javascript:void(0)')
  this.filterForm.submit()
  server.respond()

  sinon.assert.callCount(ajax, 0)
  window.GOVUK.support.history = oldHistory
}))

test('should create live count value', function () {
  window.GOVUK.documentFilter.$form = this.filterForm

  var data = { total_count: 1337 }

  window.GOVUK.documentFilter.liveResultSummary(data)
  ok(this.resultsSummary.text().indexOf('1,337 results') > -1, 'should display 1,337 results')
})

test('should update selections to match filters', sinon.test(function () {
  window.GOVUK.documentFilter.$form = this.filterForm

  var data = { total_count: 1337 }
  var formStatus = {
    selected: [
      {
        title: ['my-title'],
        id: 'topics',
        value: ['my-value']
      }
    ],
    text: [
      {
        title: ['from-date'],
        id: 'from_date',
        value: ['from-date']
      },
      {
        title: ['to-date'],
        id: 'to_date',
        value: ['to-date']
      }
    ]
  }

  var stub = this.stub(GOVUK.documentFilter, 'currentPageState')
  stub.returns(formStatus)

  window.GOVUK.documentFilter.liveResultSummary(data, formStatus)

  ok(this.resultsSummary.find('.topics-selections strong').text().indexOf('my-title') > -1)
  equal(this.resultsSummary.find('.topics-selections a').attr('data-val'), 'my-value')
  equal(this.resultsSummary.text().match(/after.from-date/).length, 1, 'not from my-date')
  equal(this.resultsSummary.text().match(/before.to-date/).length, 1, 'not to my-date')
}))

test('should request removal from document filters', sinon.test(function () {
  this.resultsSummary.append('<a href="#" data-field="topics" data-val="something">hello</a>')

  var stub = this.stub(GOVUK.documentFilter, 'removeFilters')

  this.filterForm.enableDocumentFilter()

  this.resultsSummary.find('a').click()

  if (stub.getCall(0)) {
    equal(stub.getCall(0).args[0], 'topics')
    equal(stub.getCall(0).args[1], 'something')
  } else {
    ok(stub.getCall(0), 'stub not called')
  }
}))

test('should remove selection from apropriate filter', function () {
  this.filterForm.find('option[value="dept1"]').attr('selected', 'selected')

  equal(this.filterForm.find('select option[value="dept1"]:selected').length, 1, 'selected to start')
  GOVUK.documentFilter.removeFilters('departments', 'dept1')
  equal(this.filterForm.find('select option[value="dept1"]:selected').length, 0, 'selection removed')
})

test('should select first item in filter if no item would be selected', function () {
  this.filterForm.find('option').removeAttr('selected')
  this.filterForm.find('option[value="dept1"]').attr('selected', 'selected')

  equal(this.filterForm.find('select option:selected').length, 1)
  GOVUK.documentFilter.removeFilters('departments', 'dept1')
  equal(this.filterForm.find('select option:first-child:selected').length, 1)
})

test('#_numberWithDelimiter should add commas', function () {
  equal(GOVUK.documentFilter._numberWithDelimiter(10), '10')
  equal(GOVUK.documentFilter._numberWithDelimiter(1000), '1,000')
  equal(GOVUK.documentFilter._numberWithDelimiter(1000000), '1,000,000')
})

test('#_pluralize pluralizes basic words', function () {
  equal(GOVUK.documentFilter._pluralize('badger', 0), 'badgers')
  equal(GOVUK.documentFilter._pluralize('badger', 1), 'badger')
  equal(GOVUK.documentFilter._pluralize('badger', 2), 'badgers')
})

test('#_pluralize pluralizes words ending in y', function () {
  equal(GOVUK.documentFilter._pluralize('fly', 0), 'flies')
  equal(GOVUK.documentFilter._pluralize('fly', 1), 'fly')
  equal(GOVUK.documentFilter._pluralize('fly', 2), 'flies')
})
