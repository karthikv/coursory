(function(window, document, undefined) {
  var DESCRIPTION_CONDENSED_LENGTH = 175;

  _.templateSettings = {
    escape: /\{\{(.+?)\}\}/g,
    evaluate: /\{\%(.+?)\%\}/g
  };

  var coursesTemplate = document.getElementsByClassName('courses-template')[0];
  var renderCourses = _.template(coursesTemplate.innerHTML);
  var results = document.getElementsByClassName('results')[0];

  var input = document.getElementsByTagName('input')[0];
  var prevQuery = null;

  input.addEventListener('keyup', _.debounce(function(event) {
    var query = input.value;

    // only update results if search string changed
    if (query === prevQuery) {
      return;
    }

    prevQuery = query;

    if (!query) {
      // clear results
      results.innerHTML = '';
      return;
    }

    // query for new results
    var request = new XMLHttpRequest();
    request.addEventListener('load', function() {
      if (request.status === 200) {
        var courses = JSON.parse(request.responseText);

        // condense descriptions to ~200 words
        courses.forEach(function(course) {
          if (course.description.length > DESCRIPTION_CONDENSED_LENGTH) {
            course.condensedDescription = course.description.substring(0,
              DESCRIPTION_CONDENSED_LENGTH) + '...';
          }
        });

        results.innerHTML = renderCourses({courses: courses});
      }
    });

    request.open('GET', '/search?query=' + encodeURIComponent(query), true);
    request.send();
  }, 150));

  results.addEventListener('click', function(event) {
    var target = event.target;
    while (target && !target.classList.contains('course')) {
      target = target.parentNode;
    }

    if (!target) {
      return;
    }

    // target is a .course element
    var course = target;
    var toggleButton = course.querySelector('h2 .toggle');

    if (course.classList.contains('active')) {
      course.classList.remove('active');
      toggleButton.textContent = 'Expand';
    } else {
      course.classList.add('active');
      toggleButton.textContent = 'Contract';
    }
  });
})(this, this.document);
