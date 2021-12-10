//FOR DELETING EVENTS
function deleteEvent(eventToDelete) {
  if (!signedIn) {
    document.getElementById("eventAlert").innerHTML = "<div class=\"alert alert-warning alert-dismissible\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\">&times;</button><strong>Uh oh! </strong>" + "You are not signed in!" + "</div>";
    return;
  }
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
        if (eventToDelete === event.event) {
          var url = 'https://api.sethcharleston.com/test1/delete';
          var data = {
            event: event.event,
            where: event.where,
            when: event.when,
            tickets: event.tickets
          };
          fetch(url, {
              method: 'POST',
              body: JSON.stringify(data),
              headers: {
                'Content-Type': 'application/json',
                "Authorization": token
              }
            }).then(res => res.json())
            .then(response => {
              console.log("Success:", JSON.stringify(response));
              document.getElementById("eventAlert").innerHTML = "<div class=\"alert alert-success alert-dismissible\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\">&times;</button><strong>Item Deleted! </strong>" +
                JSON.stringify(response) + "</div>";
              generateEvents();
            })
            .catch(error => {
              console.error("Error:", error);
              document.getElementById("eventAlert").innerHTML = "<div class=\"alert alert-warning alert-dismissible\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\">&times;</button><strong>Uh oh! </strong>" + error +
                "</div>";
            }).then(() => {
              timeoutID = window.setTimeout(generateEvents(), 10000, 'That was really slow!');
            });
        }
      });
    });
}
