//RESETTING TEXTAREA'S
// document.getElementById("event").value = "";
// document.getElementById("date").value = "";
// document.getElementById("time").value = "";
// document.getElementById("where").value = "";
// document.getElementById("tickets").value = "";
//FOR PUTTING TO DYNAMODB
function send_event_data() {
  if (!signedIn) {
    document.getElementById("eventAlert").innerHTML = "<div class=\"alert alert-warning alert-dismissible\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\">&times;</button><strong>Uh oh! </strong>" + "You are not signed in!" + "</div>";
    return;
  }
  var dateString = document.getElementById("date").value + "T" + document.getElementById("time").value;
  console.log(dateString)
  var eventDate = new Date(dateString);
  console.log(eventDate);
  var url = "https://api.sethcharleston.com/test1";
  var data = {
    event: document.getElementById("key").value,
    name: document.getElementById("event").value,
    where: document.getElementById("where").value,
    when: eventDate.toString(),
    tickets: document.getElementById("tickets").value
  };
  console.log(data);
  fetch(url, {
      method: "POST",
      body: JSON.stringify(data),
      headers: {
        "Content-Type": "application/json",
        "Authorization": token
      }
    })
    .then(res => res.json())
    .then(response => {
      console.log("Success:", JSON.stringify(response));
      document.getElementById("eventAlert").innerHTML = "<div class=\"alert alert-success alert-dismissible\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\">&times;</button><strong>Success! </strong>" + JSON.stringify(
        response) + "</div>";
    })
    .catch(error => {
      console.error("Error:", error);
      document.getElementById("eventAlert").innerHTML = "<div class=\"alert alert-warning alert-dismissible\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\">&times;</button><strong>Uh oh! </strong>" + error + "</div>";
    }).then(() => {
      timeoutID = window.setTimeout(generateEvents(), 10000, 'That was really slow!');
    });
}
