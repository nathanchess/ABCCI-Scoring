var currentScore = 0;

function init() {
    var scoreElement = document.getElementById("score");
    scoreElement.innerHTML = "Current Score: 0 / 5 found!"
}

function addPoint(point, desc) {
    var scoreElement = document.getElementById("score");
    var vulList = document.getElementById("list");
    var element = document.createElement("h4");
    element.textContent = desc;
    if (point != 0) {
        element.textContent = desc + " - ";
        var pointsElement = document.createElement("span");
        pointsElement.textContent = point + " point(s)";
        pointsElement.style = "color: rgb(2, 170, 2)";
        element.appendChild(pointsElement);
    }
    vulList.appendChild(element);
    currentScore+=1;
    scoreElement.innerHTML = "Current Score: " + currentScore + " / 5 found!"
}

var rendered = []

function checkPoints() {
    var xhr = new XMLHttpRequest();
    xhr.open("GET", "../hashtable.json", true);
    xhr.onreadystatechange = function() {
        if (this.readyState === 4 && this.status === 200) {
            var data = JSON.parse(this.responseText);
            for (var key in data) {
                if (data.hasOwnProperty(key) && !rendered.includes(key)) {
                    var value = data[key];
                    addPoint(value, key)
                    rendered.push(key)
                    console.log(key + ": " + value);
                }
            }
        }
    };
    xhr.send();
}

function close() {

}

window.onload = function() {
    init()
}

setInterval(checkPoints, 1000);