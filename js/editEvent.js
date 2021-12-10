// FOR EDITING EVENTS (populating the form with an existing event)
function editEvent(eventToEdit) {
  console.log('editing events');
  fetch("https://api.sethcharleston.com/test1")
    .then(function(response) {
      return response.json();
    })
    .then(function(data) {
      data.sort(function(a, b) {
        a = new Date(a.when);
        b = new Date(b.when);
        return a < b ? -1 : a > b ? 1 : 0;
      });
      data.forEach(function(event) {
        console.log(eventToEdit);
        console.log(event);
        if (eventToEdit === event.event) {
          document.getElementById("event").value = event.event;
          var date = new Date(event.when);
          document.getElementById("date").value = date.toISOString().slice(0, 10);
          document.getElementById("time").value = date.toTimeString().slice(0, 8);
          document.getElementById("where").value = event.where;
          document.getElementById("tickets").value = event.tickets;
          window.scrollTo(0, 100);
        }
      });
    });
}
