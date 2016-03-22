final int FIELDX = 768; // Number of cells in the x and y directions of the field
final int FIELDY = 256;
final int CELLSIZE = 4; // Pixel size of each cell

final int SCREENFOLLOW = 8; // Amount to shift the screen by to follow RedWing
final int MAXEFFECTSIZE = 192;

class World extends HasButtons{
  Cell[][] cells;
  PVector screenPos; // Location of the screen
  Object redWing; // The star of the show
  ArrayList<Controller> actors; // List of redWing. Literally contains nothing except redWing for now
  ArrayList<Controller> addition; // list of objects to be added in the next frame
  ArrayList<Controller> removal; // List of objects to be removed from actors this tick

  int enemies;
  int difficulty;
  int score;
  int hiscore = 0;

  int x = FIELDX*CELLSIZE;
  int y = FIELDY*CELLSIZE;
  int hx = x/2;
  int hy =  y/2;

  ArrayList<Particle> effects;
  ArrayList<Cloud> clouds;
  PVector shake;
  boolean xsplit, ysplit;

  color bleed;

  boolean showHitboxes;
  boolean showFps = false;

  float mx, my;
  ICanClick toClick = null;

  String overlayText = null;

  World() {
    resetWorld();
    showHitboxes = false;
  }

  void resetWorld(){
    cells = new Cell[FIELDX][FIELDY]; // Initiliazes cells
    for (int i = 0; i < FIELDX; i++)
      for (int j = 0; j < FIELDY; j++)
        cells[i][j] = new Cell(i, j);

    screenPos = new PVector(0, 0);
    actors = new ArrayList();
    addition = new ArrayList();
    removal = new ArrayList();

    effects = new ArrayList();
    clouds = new ArrayList();
    for(int i = 0; i < 20*effectsDensity; i++)
      clouds.add(new Cloud(random(x), random(y), random(4, 10), random(120, 180)));

    shake = new PVector(0, 0);

    bleed = color(160, 255, 255, 0);

    buttons = new ArrayList();
    target = null;
    overlayText = null;
  }

  ArrayList<ICanClick> buttons;
  SideBar sidebar = new SideBar();
  PVector menuScroll;

  void menuMain() {
    actors = new ArrayList();
    addition = new ArrayList();
    removal = new ArrayList();


    buttons.clear(); // Adding buttons
    buttons.add(new Button(-96, 32, 80, color(0, 192, 255), "Play", 0));
    buttons.add(new Button(16, 32, 80, color(0, 192, 255), "Quit", 3));
    
    screenPos.set(0, 0);
    menuScroll = new PVector(-.3, -.8);

    overlayText = null;
  }

  void beginGame(int tdiff){
    buttons.clear();

    actors.clear();
    addition.clear();
    removal.clear();

    for (int i = 0; i < FIELDX; i++)
      for (int j = 0; j < FIELDY; j++)
        cells[i][j].occupants.clear();

    redWing = new Plane(random(x), random(y), floor(random(1, NUMGUN+1)), floor(random(1, NUMBODY+1)), floor(random(1, NUMENG+1)));
    
    actors.add(new Player(redWing));

    enemies = 0;
    difficulty = tdiff;
    actors.add(new Computer(new Plane(random(x), random(y), floor(random(1, NUMGUN+1)), floor(random(1, NUMBODY+1)), floor(random(1, NUMENG+1)))));
    enemies++;
    score = 0;

    shake = new PVector(0, 0);

    bleed = color(160, 255, 255, 0);

    overlayText = null;
  }

  void menuMainRender() {
    background(0);
    screenPos.add(menuScroll);


    pushMatrix();
    translate(-screenPos.x, -screenPos.y);
    shake.mult(shakeReduction);

    // i and j are set to only retrieve relevant cells
    for (int i = floor (screenPos.x/CELLSIZE)-1; i <= ceil((screenPos.x+width)/CELLSIZE); i++) {
      pushMatrix();
      translate((i)*CELLSIZE, 0);
      for (int j = floor (screenPos.y/CELLSIZE)-1; j <= ceil((screenPos.y+height)/CELLSIZE); j++) {
        pushMatrix();
        translate(0, (j)*CELLSIZE);
        getCell(i, j).render();
        popMatrix();
      }
      popMatrix();
    }

    translate(screenPos.x, screenPos.y);
    
    // Renders the logo
    noStroke();
    fill(0, 192+32*sin((frameCount/60.0)%(2*PI)), 255);
    redWing(width/4, height/8, min(width*7/(2*26.5), height/4+32));
    textFont(f24);
    text(VERSION, width/4, height/8+32+min(width*7/(2*26.5), height/4+32));
    
    translate(-screenPos.x, -screenPos.y);
    
    xsplit = false;
    ysplit = false;
    if (world.screenPos.x < MAXEFFECTSIZE || world.screenPos.x+width > x)
      xsplit = true;
    if(world.screenPos.y < MAXEFFECTSIZE || world.screenPos.y+height > y)
      ysplit = true;

    // Renders all of the special effects
    for (Particle p : effects)
      p.render(xsplit, ysplit, true);
    
    for (Cloud c : clouds)
      c.render(xsplit, ysplit, true);
    
    for (int i = effects.size ()-1; i >= 0; i--) { // When effects time out, they are removed
      if (effects.get(i).remaining < 0) {
        Cell e = getCell(floor(effects.get(i).xpos/CELLSIZE), floor(effects.get(i).ypos/CELLSIZE));
        float magnitude = 32;
        if (effects.get(i) instanceof Smoke) {
          magnitude = 4;
        } else if (effects.get(i) instanceof Spark) {
          magnitude = 4;
        } else if (effects.get(i) instanceof Eclipse) {
          magnitude = 24;
        }
        e.col = color(hue(e.col), saturation(e.col) + min(255-saturation(e.col), int(random(magnitude, magnitude*1.2))), brightness(e.col));
        effects.remove(i);
      }
    }

    popMatrix();

    for (ICanClick b : buttons)
      b.render(this);
    if(sidebar != null)
      sidebar.render();
    
    fps();
  }

  void render() {
    background(0);
    newWave();

    for (Controller c : removal) {
      actors.remove(c);
      for (Cell l : c.location) {
        l.occupants.remove(c);
      }
    }
    removal.clear();

    for (Controller c : addition)
      actors.add(0, c);

    addition.clear();

    for (Controller c : actors)
      c.tick(); // Magic happens

    PVector target = new PVector(); // Offset vector based off of redWing's position and velocity for the screen position
    target.set((SCREENFOLLOW+1)*redWing.pos.x - width/2 - SCREENFOLLOW*redWing.last.x, (SCREENFOLLOW+1)*redWing.pos.y - height/2 - SCREENFOLLOW*redWing.last.y);

    if (screenPos.x - redWing.pos.x > hx) {
      screenPos.x -= x;
    } else if (screenPos.x - redWing.pos.x < -hx) {
      screenPos.x += x;
    }

    if (screenPos.y - redWing.pos.y > hy) {
      screenPos.y -= y;
    } else if (screenPos.y - redWing.pos.y < -hy) {
      screenPos.y += y;
    }

    screenPos.x -= (screenPos.x-target.x)/16;
    screenPos.y -= (screenPos.y-target.y)/16;


    pushMatrix();
    translate(-screenPos.x, -screenPos.y);
    translate(shake.x, shake.y);
    shake.mult(shakeReduction);

    // i and j are set to only retrieve relevant cells
    for (int i = floor (screenPos.x/CELLSIZE)-1; i <= ceil((screenPos.x+width)/CELLSIZE); i++) {
      pushMatrix();
      translate((i)*CELLSIZE, 0);
      for (int j = floor (screenPos.y/CELLSIZE)-1; j <= ceil((screenPos.y+height)/CELLSIZE); j++) {
        pushMatrix();
        translate(0, (j)*CELLSIZE);
        getCell(i, j).render();
        popMatrix();
      }
      popMatrix();
    }
    
    xsplit = false;
    ysplit = false;
    if (world.screenPos.x < MAXEFFECTSIZE || world.screenPos.x+width > x)
      xsplit = true;
    if(world.screenPos.y < MAXEFFECTSIZE || world.screenPos.y+height > y)
      ysplit = true;


    for (Controller c : actors)
      c.render(); // renders redWing

    // Renders all of the special effects
    for (Particle p : effects)
      p.render(xsplit, ysplit, true);

    for (Cloud c : clouds)
      c.render(xsplit, ysplit, true);

    for (int i = effects.size ()-1; i >= 0; i--) { // When effects time out, they are removed
      if (effects.get(i).remaining < 0) {
        Cell e = getCell(floor(effects.get(i).xpos/CELLSIZE), floor(effects.get(i).ypos/CELLSIZE));
        if(actors.contains(redWing)){
          float magnitude = 32;
          if (effects.get(i) instanceof Smoke) {
            magnitude = 4;
          } else if (effects.get(i) instanceof Spark) {
            magnitude = 4;
          } else if (effects.get(i) instanceof Eclipse) {
            magnitude = 32;
          }
          e.col = color(hue(e.col), saturation(e.col) + min(255-saturation(e.col), int(random(magnitude, magnitude*1.2))), brightness(e.col));
        }
        effects.remove(i);
      }
    }

    popMatrix();

    pushMatrix();
    if(overlayText != null){
      textFont(f36);
      translate(width/2, height/2);
      fill(0, 255, 255);
      noStroke();
      text(overlayText, -14*overlayText.length(), 18);
    }
    popMatrix();


    noStroke();
    fill(bleed);
    rect(0, 0, width, height);

    fps();

    //minimap();
  }

  void justRender(){
    pushMatrix();
    translate(-screenPos.x, -screenPos.y);
    translate(shake.x, shake.y);

    // i and j are set to only retrieve relevant cells
    for (int i = floor (screenPos.x/CELLSIZE)-1; i <= ceil((screenPos.x+width)/CELLSIZE); i++) {
      pushMatrix();
      translate((i)*CELLSIZE, 0);
      for (int j = floor (screenPos.y/CELLSIZE)-1; j <= ceil((screenPos.y+height)/CELLSIZE); j++) {
        pushMatrix();
        translate(0, (j)*CELLSIZE);
        getCell(i, j).render();
        popMatrix();
      }
      popMatrix();
    }
    
    xsplit = false;
    ysplit = false;
    if (world.screenPos.x < MAXEFFECTSIZE || world.screenPos.x+width > x)
      xsplit = true;
    if(world.screenPos.y < MAXEFFECTSIZE || world.screenPos.y+height > y)
      ysplit = true;


    for (Controller c : actors)
      c.render(); // renders redWing

    // Renders all of the special effects
    for (Particle p : effects)
      p.render(xsplit, ysplit, false);

    for (Cloud c : clouds)
      c.render(xsplit, ysplit, false);

    popMatrix();

    pushMatrix();
    if(overlayText != null){
      textFont(f36);
      translate(width/2, height/2);
      fill(0, 255, 255);
      noStroke();
      text(overlayText, -14*overlayText.length(), 18);
    }
    popMatrix();


    noStroke();
    fill(bleed);
    rect(0, 0, width, height);

    fps();
  }

  // Gets a cell with a specific index
  // Also checks boundaries
  Cell getCell(int x, int y) {
    x %= FIELDX;
    y %= FIELDY;
    if (x < 0)
      x += FIELDX;
    if (y < 0)
      y += FIELDY;
    return cells[x][y];
  }

  void newWave(){
     if (world.enemies == 0) {
      world.difficulty++;
      for (int i = 0; i < world.difficulty; i++) {
        Object p;
        p = new Plane(random(world.redWing.pos.x+width/2, world.redWing.pos.x-width/2+FIELDX*CELLSIZE), 
        random(world.redWing.pos.y+height/2, world.redWing.pos.y-height/2+FIELDY*CELLSIZE), floor(random(1, NUMGUN+1)), floor(random(1, NUMBODY+1)), floor(random(1, NUMENG+1)));
        world.addition.add(new Computer(p));
        world.enemies++;
      }
    }
  }

  // Displays the active framerate
  void fps() {
    fill(75, 255, 64);
    pushMatrix();
    translate(width-80, height-8);
    textFont(f6);
    if(showFps)
      text("FPS: "+int(frameRate*100)/100.0, 0, -24);
    text("SCORE:    "+score, 0, -12);
    text("HI-SCORE: "+hiscore, 0, 0);
    
    popMatrix();
  }

  ArrayList<Controller> collide(Controller obj) {
    ArrayList<Controller> ret = new ArrayList();
    for (Cell c : obj.location) {
      for (Controller n : c.occupants) {
        if (!ret.contains(n)) {
          ret.add(n);
        }
      }
    }
    ret.remove(obj);
    return ret;
  }
};

class Cell {
  int xi, yi; // Index of Cell in the World.cells array
  color col;
  ArrayList<Controller> occupants;

  Cell(int x, int y) {
    xi = x;
    yi = y;
    col = color(random(1*y, 16+1*y)%255, 96+48*sin(2*PI*x/FIELDX), random(208, 224));
    occupants = new ArrayList();
  }

  void render() {
    noStroke();
    if (world.showHitboxes)
      if (occupants.size() != 0) {
        strokeWeight(2);
        stroke(75, 255, 255);
      }
    fill(col);
    rect(0, 0, CELLSIZE+1, CELLSIZE+1);
  }
};

