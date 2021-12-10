function login() {
  window.location.replace('https://login.sethcharleston.com/login?response_type=token&client_id=76g2um3ps3ri68ac30agopcmc9&redirect_uri=https://edit.sethcharleston.com');
}
// for testing to see if logged in
var signedIn = false;
// grab info
var queryString = window.location.hash;
// take off begining #
queryString = queryString.slice(1);
// split query string into its component parts
var arr = queryString.split('&');

var list = {};
for (var i = 0; i < arr.length; i++) {
  // separate the keys and the values
  var a = arr[i].split('=');
  // set parameter name and value (use 'true' if empty)
  var paramName = a[0];
  var paramValue = typeof(a[1]) === 'undefined' ? true : a[1];
  list[paramName] = paramValue;
}
var url = 'https://api.sethcharleston.com/test1/access';
var token = list['id_token'];
console.log('id_token: ', token);
fetch(url, {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': token
    }
  })
  .then(res => {
    if (res.ok) {
      document.getElementById("login").innerHTML = "Signed In";
      document.getElementById("login").className = "btn btn-success";
      document.getElementById("login").disabled = true;
      signedIn = true;
    }
  })
  .then(error => {
    console.error(error);
  })
