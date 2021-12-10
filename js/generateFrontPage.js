//FOR GRABBING FROM DYNAMODB
function generateFrontPage() {
  console.log("generating Front Page Text");
  fetch("https://api.sethcharleston.com/test1/text")
    .then(function(response) {
      return response.json();
    })
    .then(function(data) {
      data.forEach(function(text) {
        console.log(text);
        if (text.location === "frontPageHeader") {
          document.getElementById("frontPageHeader").value = text.text;
          document.getElementById("frontPageHeaderInfo").innerHTML = "<div class=\"card\"><div class=\"card-body bg-info\"><p>" + text.text + "</p>" + "</div></div>";
        }
        if (text.location === "frontPageText") {
          document.getElementById("frontPageText").value = text.text;
          document.getElementById("frontPageTextInfo").innerHTML = "<div class=\"card\"><div class=\"card-body bg-info\"><p>" + text.text + "</p>" + "</div></div>";
        }
      });
    });
}
