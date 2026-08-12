// FOR EDITING SONGS
function editSong(songToEdit) {
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
        if (songToEdit === song.song) {
          document.getElementById("song").value = song.song;
          var releaseDate = new Date(song.release);
          document.getElementById("releaseDate").value = releaseDate.toISOString().slice(0, 10);
          document.getElementById("link").value = song.link;
          window.scrollTo(0, 100);
        }
      });
    });
}
