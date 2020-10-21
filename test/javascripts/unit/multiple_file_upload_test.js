module('Uploading multiple files', {
  setup: function () {
    this.fieldset = $(
      '<fieldset id="image_fields" class="images multiple_file_uploads">' +
      '<div class="file_upload well">' +
      '<div class="form-group">' +
      '<label for="edition_images_attributes_0_image_data_attributes_file">File</label>' +
      '<input id="edition_images_attributes_0_image_data_attributes_file" name="edition[images_attributes][0][image_data_attributes][file]" type="file" class="js-upload-image-input" />' +
      '<input id="edition_images_attributes_0_image_data_attributes_file_cache" name="edition[images_attributes][0][image_data_attributes][file_cache]" type="hidden" />' +
      '</div>' +
      '<div class="form-group">' +
      '<label for="edition_images_attributes_0_alt_text">Alt text</label>' +
      '<input id="edition_images_attributes_0_alt_text" name="edition[images_attributes][0][alt_text]" type="text" />' +
      '</div>' +
      '<div class="form-group">' +
      '<label for="edition_images_attributes_0_caption">Caption</label>' +
      '<textarea id="edition_images_attributes_0_caption" name="edition[images_attributes][0][caption]"></textarea>' +
      '</div>' +
      '</div>' +
      '</fieldset>')

    $('#qunit-fixture').append(this.fieldset)
    this.first_file_input = $('#edition_images_attributes_0_image_data_attributes_file')
    this.fieldset.enableMultipleFileUploads()
  }
})

var fireClickEventOnLastFileInputOf = function (fieldset) {
  fieldset.find('input[type=file]:last').click()
}

test('should add a new file input when a file is selected', function () {
  this.first_file_input.click()
  equal(this.fieldset.children('.file_upload').length, 2)
})

test('should not add a new file input when a selected file is clicked', function () {
  this.first_file_input.click()
  this.first_file_input.click()
  equal(this.fieldset.children('.file_upload').length, 2)
})

test('should continue adding new inputs as new files are selected', function () {
  for (var i = 0; i < 10; i++) {
    fireClickEventOnLastFileInputOf(this.fieldset)
  }
  equal(this.fieldset.children('.file_upload').length, 11)

  fireClickEventOnLastFileInputOf(this.fieldset)
  equal(this.fieldset.children('.file_upload').length, 12)
})

test('should increment the ID and name of the alt text input for each set of new inputs added', function () {
  fireClickEventOnLastFileInputOf(this.fieldset)
  ok($('#edition_images_attributes_1_alt_text')[0], 'input with id not found')
  ok($("input[name='edition[images_attributes][1][alt_text]']")[0], 'input with name not found')

  fireClickEventOnLastFileInputOf(this.fieldset)
  ok($('#edition_images_attributes_2_alt_text')[0], 'input with id not found')
  ok($("input[name='edition[images_attributes][2][alt_text]']")[0], 'input with name not found')
})

test('should increment the ID and name of the caption textarea for each set of new inputs added', function () {
  fireClickEventOnLastFileInputOf(this.fieldset)
  ok($('#edition_images_attributes_1_caption')[0], 'textarea with id not found')
  ok($("textarea[name='edition[images_attributes][1][caption]']")[0], 'textarea with name not found')

  fireClickEventOnLastFileInputOf(this.fieldset)
  ok($('#edition_images_attributes_2_caption')[0], 'textarea with id not found')
  ok($("textarea[name='edition[images_attributes][2][caption]']")[0], 'textarea with name not found')
})

test('should increment the referenced ID of the file label for each set of new inputs added', function () {
  fireClickEventOnLastFileInputOf(this.fieldset)
  var latestInput = this.fieldset.find("label:contains('File'):last")
  equal(latestInput.attr('for'), 'edition_images_attributes_1_image_data_attributes_file')

  fireClickEventOnLastFileInputOf(this.fieldset)
  latestInput = this.fieldset.find("label:contains('File'):last")
  equal(latestInput.attr('for'), 'edition_images_attributes_2_image_data_attributes_file')
})

test('should increment the ID and name of the file input for each set of new inputs added', function () {
  fireClickEventOnLastFileInputOf(this.fieldset)
  var latestInput = this.fieldset.find('input[type=file]:last')[0]
  equal(latestInput.id, 'edition_images_attributes_1_image_data_attributes_file')
  equal(latestInput.name, 'edition[images_attributes][1][image_data_attributes][file]')

  fireClickEventOnLastFileInputOf(this.fieldset)
  latestInput = this.fieldset.find('input[type=file]:last')[0]
  equal(latestInput.id, 'edition_images_attributes_2_image_data_attributes_file')
  equal(latestInput.name, 'edition[images_attributes][2][image_data_attributes][file]')
})

test('should increment the ID and name of the hidden cache input for each set of new inputs added', function () {
  fireClickEventOnLastFileInputOf(this.fieldset)
  var latestInput = this.fieldset.find('input[type=hidden]:last')[0]
  equal(latestInput.id, 'edition_images_attributes_1_image_data_attributes_file_cache')
  equal(latestInput.name, 'edition[images_attributes][1][image_data_attributes][file_cache]')

  fireClickEventOnLastFileInputOf(this.fieldset)
  latestInput = this.fieldset.find('input[type=hidden]:last')[0]
  equal(latestInput.id, 'edition_images_attributes_2_image_data_attributes_file_cache')
  equal(latestInput.name, 'edition[images_attributes][2][image_data_attributes][file_cache]')
})

test('should make the value of the text input blank for each set of new inputs added', function () {
  this.fieldset.find('input[type=text]:last').val('not-blank')
  fireClickEventOnLastFileInputOf(this.fieldset)
  var latestInput = this.fieldset.find('input[type=text]:last')
  equal(latestInput.val(), '')
})

test('should make the value of the caption textarea blank for each set of new inputs added', function () {
  this.fieldset.find('#edition_images_attributes_0_caption').append('not-blank')
  fireClickEventOnLastFileInputOf(this.fieldset)
  equal($('#edition_images_attributes_1_caption').val(), '')
})

test('should set the value of the hidden cache input to blank for each new input added', function () {
  $('input[type=hidden]:last').val('not-blank')
  fireClickEventOnLastFileInputOf(this.fieldset)
  var latestInput = this.fieldset.find('input[type=hidden]:last')
  equal(latestInput.val(), '')
})

test('should set the text of the already_uploaded element to blank for each new input added', function () {
  var alreadyUploaded = $('<span class="already_uploaded">some-file.pdf already uploaded</span>')
  $('input[type=file]:last').after(alreadyUploaded)
  fireClickEventOnLastFileInputOf(this.fieldset)
  equal(this.fieldset.find('.already_uploaded').length, 2)
  equal(this.fieldset.find('.already_uploaded:last').text(), '')
})

module('Uploading multiple files after file field validation error', {
  setup: function () {
    this.fieldset = $(
      '<fieldset id="image_fields" class="images multiple_file_uploads">' +
      '<div class="file_upload well">' +
      '<div class="field_with_errors">' +
      '<label for="edition_images_attributes_0_image_data_attributes_file">File</label>' +
      '</div>' +
      '<div class="field_with_errors">' +
      '<input id="edition_images_attributes_0_image_data_attributes_file" name="edition[images_attributes][0][image_data_attributes][file]" type="file" class="js-upload-image-input" />' +
      '</div>' +
      '<input id="edition_images_attributes_0_image_data_attributes_file_cache" name="edition[images_attributes][0][image_data_attributes][file_cache]" type="hidden" />' +
      '</div>' +
      '</fieldset>')
    $('#qunit-fixture').append(this.fieldset)
    this.fieldset.enableMultipleFileUploads()
  }
})

test('should add a new file input when a file is selected', function () {
  fireClickEventOnLastFileInputOf(this.fieldset)
  equal(this.fieldset.children('.file_upload').length, 2)
})

test('should copy the file label without error wrapper for each set of new inputs added', function () {
  fireClickEventOnLastFileInputOf(this.fieldset)
  equal(this.fieldset.find("label:contains('File'):last").parent().hasClass('field_with_errors'), false)
  equal(this.fieldset.find(".field_with_errors label:contains('File')").length, 1)
})

test('should copy the file input without error wrapper for each set of new inputs added', function () {
  fireClickEventOnLastFileInputOf(this.fieldset)
  equal(this.fieldset.find('input[type=file]').length, 2)
  equal(this.fieldset.find('.field_with_errors input[type=file]').length, 1)
})
