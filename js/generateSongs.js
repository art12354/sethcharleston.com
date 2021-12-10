// GENERATING EXISTING SONGS
function escapeHtml(str) {
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#039;");
}
function generateSongs() {
  //RESETTING TEXTAREA'S
  document.getElementById("song").value = "";
  document.getElementById("link").value = "";
  document.getElementById("releaseDate").value = "";

  console.log("generating songs");
  var x = "";
  fetch("https://api.sethcharleston.com/test1/songs")
    .then(function(songResponse) {
      return songResponse.json();
    })
    .then(function(songData) {
      songData.sort(function(songA, songB) {
        songA = new Date(songA.release);
        songB = new Date(songB.release);
        return songA < songB ? -1 : songA > songB ? 1 : 0;
      });
      songData.forEach(function(song) {
        console.log(song);
        var releaseDate = new Date(song.release);
        x += `<div class="card">
                <div class="card-body bg-info">
                  <p>${song.song}</p>
                  <p>${releaseDate.toDateString()}</p>
                  <p>${song.link}</p>
                  <button class="btn btn-dark mr-3" onclick="editSong(${song.song})">edit</button>
                  <button class="btn btn-danger" onclick="deleteSong(${song.song})">delete</button>
                </div>
              </div>`;
        document.getElementById("songInfo").innerHTML = x;
      });
    });
}
