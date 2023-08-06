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
  var eventDate = new Date(document.getElementById("date").text + "T" + document.getElementById("time").text);
  console.log(eventDate);
  var url = "https://api.sethcharleston.com/test1";
  var data = {
    event: document.getElementById("key").text,
    name: document.getElementById("event").text,
    where: document.getElementById("where").text,
    when: eventDate.toString(),
    tickets: document.getElementById("tickets").text
  };
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
