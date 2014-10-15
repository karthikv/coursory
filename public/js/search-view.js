(function(window, document, undefined) {
  var DESCRIPTION_CONDENSED_LENGTH = 175;
  var NUMBER_REGEX = /^\d+$/;

  // make underscore templates work with {% %} and {{ }} delimiters
  _.templateSettings = {
    escape: /\{\{(.+?)\}\}/g,
    evaluate: /\{\%(.+?)\%\}/g
  };

  var coursesTemplate = document.getElementsByClassName('courses-template')[0];
  var renderCourses = _.template(coursesTemplate.innerHTML);

  var results = document.getElementsByClassName('results')[0];
  var searchBox = document.querySelector('input[type="text"]');
  var checkboxes = document.querySelectorAll('input[type="checkbox"]');
  var loading = document.getElementsByClassName('loading')[0];

  var oldQuery = null;
  var oldFilters = null;
  var page = 1;

  /* Returns the active filters based on checked checkboxes. */
  function getFilters() {
    var filters = {};

    SearchModel.FILTER_CATEGORIES.forEach(function(category) {
      var filterCheckboxes = document.querySelectorAll(
        '.' + category + ' input[type="checkbox"]');
      var values = [];

      // collect values from all checked checkboxes
      Array.prototype.forEach.call(filterCheckboxes, function(checkbox) {
        if (checkbox.checked) {
          var value = checkbox.value;
          if (NUMBER_REGEX.test(value)) {
            value = parseInt(value, 10);
          }

          values.push(value);
        }
      });

      if (values.length > 0) {
        filters[category] = values;
      }
    });

    return filters;
  }

  /* Updates the search results based on the inputted query and filters.
   * advancePage specifies whether to advance to the next page of results. */
  function updateSearchResults(event, advancePage) {
    var query = searchBox.value;
    var filters = getFilters();

    if (query === oldQuery && _.isEqual(filters, oldFilters) && !advancePage) {
      return;
    }

    if (!query && _.isEmpty(filters)) {
      // nothing is being searched for
      results.innerHTML = renderCourses({courses: []});
    } else {
      page = advancePage ? page + 1 : 0;
      loading.classList.add('active');

      SearchModel.match(query, filters, page, function(courses) {
        loading.classList.remove('active');

        // limit length of descriptions
        courses.forEach(function(course) {
          if (course.description.length > DESCRIPTION_CONDENSED_LENGTH) {
            course.condensedDescription = course.description.substring(0,
              DESCRIPTION_CONDENSED_LENGTH) + '...';
          }
        });

        var coursesHTML = renderCourses({courses: courses});
        if (advancePage && courses.length === 0) {
          page -= 1;  // page number has saturated
        } else if (advancePage && courses.length > 0) {
          results.innerHTML += coursesHTML;
        } else {
          results.innerHTML = coursesHTML;
        }
      });
    }

    oldQuery = query;
    oldFilters = filters;
  }

  // update results when user input changes
  searchBox.addEventListener('keyup', _.debounce(updateSearchResults, 150));
  Array.prototype.forEach.call(checkboxes, function(checkbox) {
    checkbox.addEventListener('change', updateSearchResults);
  });

  // infinite scroll: update search results when user scrolls to bottom
  window.addEventListener('scroll', _.debounce(function() {
    var scrollY = window.scrollY || document.body.scrollTop;

    if (window.innerHeight + scrollY >= document.body.offsetHeight) {
      updateSearchResults(null, true);
    }
  }, 100));

  // expand/collapse elements that have a toggle button
  window.addEventListener('click', function(event) {
    // event delegation: find .toggle element that was clicked
    var target = event.target;
    while (target instanceof HTMLElement &&
           !target.classList.contains('toggle')) {
      target = target.parentNode;
    }

    if (!(target instanceof HTMLElement)) {
      return;
    }

    // target is a .toggle element
    var toggleButton = target;
    var course = toggleButton.parentNode.parentNode;

    // toggle .active class and change text
    if (course.classList.contains('active')) {
      course.classList.remove('active');
      toggleButton.textContent = 'Expand';
    } else {
      course.classList.add('active');
      toggleButton.textContent = 'Collapse';
    }
  });

  updateSearchResults();
  searchBox.focus();
})(this, this.document);
