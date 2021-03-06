DashboardMetadataField = function() {
  var cLickJSAddMetadataField = function() {
    $('form').on('click', '.js-add-metadata-fields', function(e) {
      e.preventDefault();
      blueprint = $(e.target).data("blueprint");

      var association = $(e.target).data("association");
      var new_id = new Date().getTime();
      var regexp = new RegExp("new_" + association, "g");
      $('.js-metadata-container').append(blueprint.replace(regexp, new_id));
    });
  }

  var clickJSRemoveMetadataField = function() {
    $('form').on('click', '.js-remove-metadata-fields',
    function(e) {
      parent = $(this).closest('.js-metadata-fields')
      parent.find('input').val('');
      parent.removeClass('d-flex');
      parent.hide();
    })
  }

  this.init = function() {
    cLickJSAddMetadataField();
    clickJSRemoveMetadataField();
  }
}
