//FOR GRABBING FROM DYNAMODB
function generateBio() {
  console.log("generating bio");
  fetch("https://api.sethcharleston.com/test1/text")
    .then(function(response) {
      return response.json();
    })
    .then(function(data) {
      data.forEach(function(text) {
        console.log(text);
        if (text.location === "bio") {
          document.getElementById("bioText").value = text.text;
          document.getElementById("bioInfo").innerHTML = "<div class=\"card\"><div class=\"card-body bg-info\"><p>" + text.text + "</p>" + "</div></div>";;
        }
      });
    });
}
