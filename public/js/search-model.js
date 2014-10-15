(function(window, document, undefined) {
  var SearchModel = {};

  SearchModel.FILTER_CATEGORIES = ['terms', 'units', 'gers', 'subjects'];

  /* Searches for courses that match the given query and filters. Calls the
   * given callback with an array of matching courses.
   *
   * query should be a string. filters should be an object with up to four
   * keys: terms, units, gers, and subjects. values should be arrays of strings
   * that filter the respective key. For instance, { units: [1, 2] } limits the
   * units to either 1 or 2. page should be which page to return (0-indexed).
   */
  SearchModel.match = function(query, filters, page, callback) {
    // add query to querystring
    var qs = 'page=' + encodeURIComponent(page) + '&query=' +
      encodeURIComponent(query);

    // add each filter to querystring
    this.FILTER_CATEGORIES.forEach(function(category) {
      if (filters[category] && _.isArray(filters[category])) {
        qs += '&' + category + '=' +
          encodeURIComponent(JSON.stringify(filters[category]));
      }
    });

    // query for new results
    var request = new XMLHttpRequest();
    request.addEventListener('load', function() {
      if (request.status === 200) {
        var courses = JSON.parse(request.responseText);
        callback(courses);
      }
    });

    request.open('GET', '/search?' + qs, true);
    request.send();
  };

  window.SearchModel = SearchModel;
})(this, this.document);
