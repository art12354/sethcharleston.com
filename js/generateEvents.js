// GENERATING EXISTING EVENTS
function generateEvents() {
  console.log("generating events")
  var x = "";
  fetch("https://api.sethcharleston.com/test1")
    .then(function(response) {
      var jsonResponse = response.json().Items
      console.log(jsonResponse)
      return jsonResponse;
    })
    .then(function(data) {
      data.sort(function(a, b) {
        a = new Date(a.when);
        b = new Date(b.when);
        return a < b ? -1 : a > b ? 1 : 0;
      });
      data.forEach(function(event) {
        console.log(event);
        var when = new Date(event.when);
        x += `<div class="card">
                <div class="card-body bg-info">
                  <p>${event.name}</p>
                  <p>${when.toDateString()} at ${when.toTimeString()}</p>
                  <p>${event.where}</p>
                  <p>${event.tickets}</p>
                  <button class="btn btn-dark mr-3" onclick="editEvent('${event.event}')">edit</button>
                  <button class="btn btn-danger" onclick="deleteEvent('${event.event}')">delete</button>
                </div>
              </div>`;
        document.getElementById("eventInfo").innerHTML = x;
      });
    });
}
