//FOR PUTTING TO DYNAMODB
function send_song_data() {
  if (!signedIn) {
    document.getElementById("songAlert").innerHTML = "<div class=\"alert alert-warning alert-dismissible\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\">&times;</button><strong>Uh oh! </strong>" + "You are not signed in!" + "</div>";
    return;
  }
  //1995-12-17T03:24:00
  var eventDate = new Date(document.getElementById("releaseDate").value + "T00:00:00");
  console.log(eventDate);
  var url = "https://api.sethcharleston.com/test1/songs";
  var data = {
    song: document.getElementById("song").value,
    link: document.getElementById("link").value,
    release: eventDate.toString()
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
      document.getElementById("songAlert").innerHTML = "<div class=\"alert alert-success alert-dismissible\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\">&times;</button><strong>Success! </strong>" + JSON.stringify(
        response) + "</div>";
    })
    .catch(error => {
      console.error("Error:", error);
      document.getElementById("songAlert").innerHTML = "<div class=\"alert alert-warning alert-dismissible\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\">&times;</button><strong>Uh oh! </strong>" + error + "</div>";
    }).then(() => {
      timeoutID = window.setTimeout(generateSongs(), 10000, 'That was really slow!');
    });
}
