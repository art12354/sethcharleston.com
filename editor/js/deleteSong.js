//FOR DELETING SONGS
function deleteSong(songToDelete) {
  if (!signedIn) {
    document.getElementById("songAlert").innerHTML = "<div class=\"alert alert-warning alert-dismissible\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\">&times;</button><strong>Uh oh! </strong>" + "You are not signed in!" + "</div>";
    return;
  }
  fetch("https://api.sethcharleston.com/test1/songs")
    .then(function(response) {
      return response.json();
    })
    .then(function(data) {
      data.sort(function(a, b) {
        a = new Date(a.release);
        b = new Date(b.release);
        return a < b ? -1 : a > b ? 1 : 0;
      });
      data.forEach(function(song) {
        if (songToDelete === song.song) {
          var url = 'https://api.sethcharleston.com/test1/delete_song';
          var data = {
            song: song.song,
            link: song.link,
            release: song.release
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
              document.getElementById("songAlert").innerHTML = "<div class=\"alert alert-success alert-dismissible\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\">&times;</button><strong>Item Deleted! </strong>" +
                JSON.stringify(response) + "</div>";
            })
            .catch(error => {
              console.error("Error:", error);
              document.getElementById("songAlert").innerHTML = "<div class=\"alert alert-warning alert-dismissible\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\">&times;</button><strong>Uh oh! </strong>" + error +
                "</div>";
            }).then(() => {
              timeoutID = window.setTimeout(generateSongs(), 10000, 'That was really slow!');
            });
        }
      });
    });
}
