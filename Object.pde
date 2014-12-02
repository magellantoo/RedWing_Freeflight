// Superclass Object is a body which exist in the world. 
// They must exist with a controller
abstract class Object {
  // Current position and previous frame position
  PVector pos;
  PVector last; // Last is used for verlet integration. See wikipedia for more information

  // Radii
  float sizex; // Tail to nose /2
  float sizey; // Wingspan /2
  float sizez; // Bottom to top
  float dir; // Direction plane is facing in radians
  float roll; // The roll of the plane in radians (aka rotation about the local x axis)

  float turnspd; // Amount of radians the vehicle is capable of changing its facing direction by in each frame
  float speed; // Name is misleading, actually refers to the change in velocity each frame while the plane is accelerating
  PVector terminal; // Terminal velocities in the x direction based off of speed and in the y direction based off of gravity

  Controller controller; 

  int firerate;
  int cooldown;
  
  color col;

  Object() {
  }

  void tick() {
    // Ensures dir is always between 0 and 2*PI
    if (dir < 0) 
      dir += 2*PI; 
    dir %= 2*PI;
    // Same for roll
    if (roll < 0) 
      roll += 2*PI; 
    roll %= 2*PI;

    // Makes the roll level out
    if (dir < PI/2 || dir > 3*PI/2) { // Checks if vehicle is facing right
      if (roll < PI) // If nose is pitched up, roll will be between 0 and PI
          roll *= 0.98; // In this case, roll approaches 0
      else // If nose is pitched down, roll will be between PI and 2*PI
      roll = (roll - 2*PI)*.98; // Otherwise, roll approaches 2*PI
    } else { // If plane is facing left
      roll = PI + (roll - PI)*.98; // Roll will approach PI
    }

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

    // Gravity
    last.add(0, -GRAVITY*(1-abs(pos.x - last.x)/terminal.x), 0); // As the x velocity increases, the plane generates lift, and gravity has less of an effect

    // Simple verlet integration for movement
    // Velocity is calculated from the delta of the last position and current position. 
    PVector temp = new PVector(pos.x, pos.y);
    pos.add(FRICTION*(pos.x - last.x), FRICTION*(pos.y - last.y), 0);
    last.set(temp.x, temp.y);
  }

  void render() {
  }

  // input sent from the controller
  void controls(boolean left, boolean right, boolean up, boolean down, boolean fire) {
    // Turning (or technically, changing pitch)
    if (left) {
      dir -= turnspd;
      roll -= turnspd;
    }
    if (right) {
      dir += turnspd;
      roll += turnspd;
    } // Accelerating
    if (up) {
      last.add(cos(dir)*-speed, sin(dir)*-speed, 0);
    }
    if (fire) {
      if (cooldown == 0) {
        fire();
        cooldown = firerate;
      }
    }
    if (cooldown != 0)
      cooldown --;
  }

  // Not implemented yet, game is currently peaceful
  void fire() {
    Bullet b = new Bullet(this);
    world.addition.add(new BulletController(b));
  }
}
