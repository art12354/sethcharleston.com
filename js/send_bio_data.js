//FOR PUTTING TO DYNAMODB
function send_bio_data() {
  if (!signedIn) {
    document.getElementById("bioAlert").innerHTML = "<div class=\"alert alert-warning alert-dismissible\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\">&times;</button><strong>Uh oh! </strong>" + "You are not signed in!" + "</div>";
    return;
  }
  var url = "https://api.sethcharleston.com/test1/text/";
  var data = [{
    location: "bio",
    text: document.getElementById("bioText").value
  }];
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
      document.getElementById("bioAlert").innerHTML = "<div class=\"alert alert-success alert-dismissible\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\">&times;</button><strong>Success! </strong>" + JSON.stringify(
        response) + "</div>";
    })
    .catch(error => {
      console.error("Error:", error);
      document.getElementById("bioAlert").innerHTML = "<div class=\"alert alert-warning alert-dismissible\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\">&times;</button><strong>Uh oh! </strong>" + error + "</div>";
    });
}
