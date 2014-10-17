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
  var noMorePages = false;
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

  /* Searches based on the inputted query and filters. advancePage specifies
   * whether to advance to the next page of search results. If advancePage is
   * false, this function begins a new search with the latest user input. */
  function search(advancePage) {
    var query;
    var filters;

    if (advancePage) {
      query = oldQuery;
      filters = oldFilters;

      // can't advance if there aren't any more pages
      if (noMorePages) {
        return;
      }

      page = page + 1;
    } else {
      query = searchBox.value;
      filters = getFilters();

      // don't update if results won't change
      if (query === oldQuery && _.isEqual(filters, oldFilters)) {
        return;
      }

      oldQuery = query;
      oldFilters = filters;
      page = 0;
      noMorePages = false;
    }

    if (!query && _.isEmpty(filters)) {
      // nothing is being searched for
      results.innerHTML = renderCourses({
        courses: [],
        appendResults: false,
        noSearch: true
      });
      return;
    }

    // perform search
    loading.classList.add('active');
    SearchModel.match(query, filters, page, function(courses) {
      loading.classList.remove('active');

      updateSearchResults(courses, advancePage);
      noMorePages = courses.length == 0;
    });
  }

  /* Updates the search results in the DOM based on the given array of courses.
   * Appends the courses if appendResults is true. */
  function updateSearchResults(courses, appendResults) {
    // limit length of descriptions
    courses.forEach(function(course) {
      if (course.description.length > DESCRIPTION_CONDENSED_LENGTH) {
        course.condensedDescription = course.description.substring(0,
          DESCRIPTION_CONDENSED_LENGTH) + '...';
      }
    });

    var coursesHTML = renderCourses({
      courses: courses,
      appendResults: appendResults,
      noSearch: false
    });

    if (appendResults) {
      results.innerHTML += coursesHTML;
    } else {
      results.innerHTML = coursesHTML;
    }
  }

  /* Begins a new search with the latest user input. See documentation for
   * the `search()` function. */
  function beginSearch() {
    search(false);
  }

  // update results when user input changes
  searchBox.addEventListener('keyup', _.debounce(beginSearch, 150));
  Array.prototype.forEach.call(checkboxes, function(checkbox) {
    checkbox.addEventListener('change', beginSearch);
  });

  // infinite scroll: update search results when user scrolls to bottom
  window.addEventListener('scroll', _.debounce(function() {
    var scrollY = window.scrollY || document.body.scrollTop;

    if (window.innerHeight + scrollY >= document.body.offsetHeight) {
      search(true);
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

  search(false);
  searchBox.focus();
})(this, this.document);
