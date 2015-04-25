// Square buttons for the menu
class Button {
  float posx, posy, size; // Size is width
  color col; // Color
  String text;
  int button; // The index for what to do when the button is clicked
  boolean hover; // Whether or not the button is hovered over

    Button(float tx, float ty, float ts, color tcol, String tt, int tb) { // Large constructor caller because why not
    posx = tx; 
    posy = ty; 
    size = ts; 
    col = tcol;
    text = tt;
    button = tb;
    hover = false;
  }

  void render(HasButtons screen) {
    pushMatrix();
    translate(width/2+posx, height/2+posy);
    if (mouseX > width/2+posx && mouseX < width/2+posx+size && mouseY > height/2+posy && mouseY < height/2+posy+64) // Check hover
      hover = true;
    else {
      hover = false;
      if (screen.target == this)
        screen.target = null;
    }

    if (hover){
      screen.target = this;
      if (mousePressed) { 
        fill(255);
      } else {
        fill(255, 128);
      }
    }
    else if(button == 5 && player == mouse)
      fill(255, 192);
    else if(button == 6 && player == keyboard)
      fill(255, 192);
    else 
      fill(255, 64); // Transparent

    strokeWeight(3.5);
    stroke(col);
    rect(0, 0, size, 56);

    fill(col);
    textFont(f36);
    text(text, size/2 - text.length()*13.3, 44);

    popMatrix();
  }

  void click() {
    switch(button) {
    case 0: // Begin game
      world.beginGame(2);
      screen = 0;
      break;
    /*case 1: // Stats
      break;*/
    case 2: // Settings
      world.menuSettings();
      screen = 1;
      break;
    case 3: // exit game
      //saveOptions();
      //saveStats();
      //exit();
      text = "Disabled";
      break;
    case 4: // Main Menu
      world.menuMain();
      screen = 1;
      break;
    case 5: // Set controls to mouse
      player = mouse;
      break;
    case 6: // Set controls to keyboard
      player = keyboard;
      break;
    }
    /*case 7:
      debug = !debug;
      text = "Debug:"+(debug ? "ON " : "OFF");
      break;
    case 8:
      showCells = !showCells;
      text = "Cells:"+(showCells ? "ON " : "OFF");
      break;
    case 9:
      showGrid = !showGrid;
      text = "Grid :"+(showGrid ? "ON " : "OFF");
      break;
    case 10:
      showFPS = !showFPS;
      text = "FPS  :"+(showFPS ? "ON " : "OFF");
      break;
    case 11: // Statistics
      switchtoStats();
      break;
    case 12: // Reset Statistics
      text = "Really?";
      button = 13;
      break;
    case 13: // Confirmation for resetting stats
      text = "Done!";
      button = 12;
      for (int i = 0; i < 4; i++)
        stats[i] = 0;
      break;
      */
  }
};

abstract class HasButtons{
  Button target;
}

