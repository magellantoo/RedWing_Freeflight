// Simple projectile 
final float BULLETVEL = 12;

class Bullet extends Object {

  Bullet(Object origin) {
    pos = new PVector(origin.pos.x, origin.pos.y);
    dir = origin.dir;
    last = new PVector(origin.last.x-cos(dir)*BULLETVEL, origin.last.y-sin(dir)*BULLETVEL);
  }

  void tick() {
    if (pos.y < 0) { // Allows infinite translationg from ceiling to floor and side to side
      pos.y += FIELDY*CELLSIZE;
      last.y += FIELDY*CELLSIZE;
    }
    if (pos.y >= FIELDY*CELLSIZE) {
      pos.y -= FIELDY*CELLSIZE;
      last.y -= FIELDY*CELLSIZE;
    }
    if (pos.x < 0) {
      pos.x += FIELDX*CELLSIZE;
      last.x += FIELDX*CELLSIZE;
    }
    if (pos.x > FIELDX*CELLSIZE) {
      pos.x -= FIELDX*CELLSIZE;
      last.x -= FIELDX*CELLSIZE;
    }

    // Simple verlet integration for movement
    // Velocity is calculated from the delta of the last position and current position. 
    PVector temp = new PVector(pos.x, pos.y);
    pos.add(pos.x - last.x, pos.y - last.y, 0);
    last.set(temp.x, temp.y);
  }

  void render() {
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(dir);
    strokeWeight(2);
    stroke(255, 192+64*controller.life/120);
    line(0, 0, 16, 0);
    popMatrix();
  }
}

class BulletController extends Controller {  
  BulletController(Bullet b, Controller c) {
    vehicle = b;
    life = 120;

    location = new ArrayList();

    // Sets a static check size
    checkx = 0;
    checky = 0;

    b.controller = this;

    origin = c;
  }

  void tick() {
    life--;
    if (life <= 0) {
      world.removal.add(this);
    }
    vehicle.tick();
    update();
  }

  void render() {
    pushMatrix();
    if (vehicle.pos.x < world.screenPos.x)
      translate(FIELDX*CELLSIZE, 0);
    else if (vehicle.pos.x > world.screenPos.x+width)
      translate(-FIELDX*CELLSIZE, 0);

    if (vehicle.pos.y < world.screenPos.y)
      translate(0, FIELDY*CELLSIZE);
    else if (vehicle.pos.y > world.screenPos.y+height)
      translate(0, -FIELDY*CELLSIZE);

    vehicle.render();

    popMatrix();
  }

  void collide(Controller c) {
    c.life -= 1;
    world.shake.add(signum(random(-1, 1))*random(4, 8), signum(random(-1, 1))*random(4, 8), 0);
    world.effects.add(new Explosion(c.vehicle.pos.x, c.vehicle.pos.y, random(16, 24)));
    world.removal.add(this);
  }
}

// Laser Beam

class Beam extends Object {

  Beam(Object origin) {
    pos = new PVector(origin.pos.x, origin.pos.y);
    dir = origin.dir;
  }

  void tick() {
  }

  void render() {
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(dir);
    strokeWeight(2+sizex/200);
    stroke(frameCount%256, 255, 255);
    line(24, 0, sizex, 0);
    
    float xi = cos(dir);
    float yi = sin(dir);
    
    for(int i = 32; i < sizex; i+= 32){
      world.effects.add(new Spark(pos.x+i*xi, pos.y+i*yi, random(8, 16), color(int(random(0, 255)), 255, 255), int(random(6, 8)), random(0, 2*PI)));
    }


    popMatrix();
  }
}

class BeamController extends Controller {  
  float len;

  BeamController(Beam b, Controller c, float l) {
    vehicle = b;
    life = l/4;

    location = new ArrayList();

    b.controller = this;

    origin = c;

    len = 200+8*l;
    b.sizex = len;
  }

  void tick() {
    if (life < 0) {
      world.removal.add(this);
    }    
    vehicle.tick();
    update();
    life--;
  }

  // Update override because it's a laser beam
  void update() {
    vehicle.pos.set(origin.vehicle.pos.x, origin.vehicle.pos.y);
    vehicle.dir = origin.vehicle.dir;
    // Removes contoller from previously occupied cells
    for (Cell c : location)
      c.occupants.remove(this);
    // Clears occupied cells
    location.clear();
    // Adds cells in the x and y direction from the vehicle position to its array of occupied cells
    // Also adds this controller to the list of occupants for each cell
    for (float i = 0; i <= len; i += CELLSIZE) {
      Cell tempc = world.getCell(floor((vehicle.pos.x + i*cos(vehicle.dir))/CELLSIZE), floor((vehicle.pos.y + i*sin(vehicle.dir))/CELLSIZE));
      location.add(tempc);
      tempc.occupants.add(this);
    }
  }

  void render() {
    pushMatrix();
    vehicle.pos.set(origin.vehicle.pos.x, origin.vehicle.pos.y);
    vehicle.render();

    popMatrix();
  }

  void collide(Controller c) {
    c.life -= len/1024;
    world.effects.add(new Explosion(c.vehicle.pos.x, c.vehicle.pos.y, random(8, 12)));
  }
}
