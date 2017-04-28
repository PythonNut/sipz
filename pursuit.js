var updateParameters;
function callUpdate() {
  updateParameters();
}

window.onload=function(){
  //canvas
var c = document.getElementById("canvas");
var ctx = c.getContext("2d");
//prey
var prey = new Image();
var pred = new Image();





prey.src = "prey.png";
pred.src = "kozai.png";
//pred.src = "kozai.png";

//prey movement
var preyX = 50;
var preyY = 50;
var preyHeight = 600;
var preySpeed = 0;
var preydX = 0;
var preydY = 0;
var predX = 50;
var predY = 250;
var preddX = 0;
var preddY = 0;
var zigWidth = 0;
var zigHeight = 0;
var inertia = .1; //THis is k/m
var drag = 1; // This is C/m for drag porportional to vel.
var inertSlider = document.getElementById("kozStick");
var draggySlider = document.getElementById("kozDrag");
var preySlider = document.getElementById("preySpeed");
var zHeightSlider = document.getElementById("zigHeight");
var zWidthSlider = document.getElementById("zigWidth");
var isZig = document.getElementById("zig");
var isLine = document.getElementById("line");




updateParameters = function() {
  //alert("updating!");
  preyX = 50;
  preyY = 300;
  predX = 50;
  predY = 250;
  preddX = 0;
  preddY = 0;
  inertia = parseFloat(inertSlider.value);
  drag = parseFloat(draggySlider.value);
  preySpeed = parseFloat(preySlider.value);



  if (isZig.checked) {
    zigHeight = parseInt(zHeightSlider.value);
    zigWidth = parseInt(zWidthSlider.value);
    preydX = preySpeed * zigWidth / Math.sqrt(zigWidth*zigWidth + zigHeight * zigHeight);
    preydY = preySpeed * zigHeight / Math.sqrt(zigWidth*zigWidth + zigHeight * zigHeight);
  }
}

updateParameters();
var updateObjects = function() {
    //calculate time passed
    //var elapsedTime = 1000 / fps;
    //animate


    //for zig zag
    if (isZig.checked) {





      if (preyX>1350){
          updateParameters();
      }
      preyX += preydX;

      if (preyY>300 + zigHeight/2) preydY = -preydY;
      if (preyY<300 - zigHeight/2) preydY = -preydY;
      preyY += preydY;


      //predator movement

    }
    if (isLine.checked) {
      if (preyX > 1350) updateParameters();
      preyX += preySpeed;
    }
    var xDist = preyX - predX;
    var yDist = preyY - predY;

  //  var predaX = inertia * xDist - preddX * drag;
  //  var predaY = inertia * yDist - preddY * drag;



    var predaX = inertia * xDist /**// Math.sqrt(xDist*xDist + yDist * yDist)/**/- preddX*drag;
    var predaY = inertia * yDist /**// Math.sqrt(xDist*xDist + yDist * yDist)/**/- preddY*drag;

    preddX += predaX;
    preddY += predaY;


    predX += preddX;
    predY += preddY;

}

drawFunc();

function drawFunc() {
    //do animation logic
    updateObjects();

    //draw new stuff
    ctx.clearRect(0, 0, c.width, c.height);
    ctx.drawImage(pred, predX - 43, predY - 50);
    ctx.drawImage(prey, preyX - 12, preyY - 15);


    /*ctx.fillStyle = "#FF0000";
    ctx.beginPath();

    ctx.arc(preyX, preyY, 50, Math.PI * 0 , Math.PI * 2, false);
    ctx.fill();*/
    //wait for next frame
    requestAnimationFrame(drawFunc);

    //because the web is annoying, here's a hack to make it work
    /*if (window.requestAnimationFrame) {
        requestAnimationFrame(drawFunc);
    } else if (window.webkitRequestAnimationFrame) {
        webkitRequestAnimationFrame(drawFunc);
    } else if (window.mozRequestAnimationFrame) {
        mozRequestAnimationFrame(drawFunc);
    }*/
}

};
