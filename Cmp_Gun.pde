final int NUMGUN = 2;

abstract class Gun {
  Object platform;
  int firerate; // The minimum number of frames between shots
  int cooldown; // The number of frames remaining before a shot can be made
  float multiplier;


  Gun() {
  }

  void shoot(boolean fire) {
  }

  void render() {
  }
}

class MachineGun extends Gun {

  MachineGun(int fire, Object p) {
    firerate = fire;
    cooldown = 0;
    platform = p;
    multiplier = 1;
  }


  void shoot(boolean fire) {
    if (fire)
      if (cooldown == 0) {
        Bullet b = new Bullet(platform);
        world.addition.add(new BulletController(b, platform.controller, multiplier));
        cooldown = firerate;
      }

    if (cooldown != 0)
      cooldown --;
  }
}

class LaserBeam extends Gun {
  float charge;

  LaserBeam(Object p) {
    platform = p;
    multiplier = 1;
  }


  void shoot(boolean fire) {
    if (fire) {
      if (charge < 100)
        charge ++;
    } else if (charge > 20) {
      Beam b = new Beam(platform);
      world.addition.add(new BeamController(b, platform.controller, charge, multiplier));
      charge = 0;
    }
  }

  void render() {
    if (charge > 5) {
      fill(frameCount%256, 255, 255);
      ellipse(32, 0, 5+charge/5, 5+charge/5);
    }
  }
}

class GrenadeLauncher extends Gun {

  GrenadeLauncher(int fire, Object p) {
    firerate = fire;
    cooldown = 0;
    platform = p;
    multiplier = 1;
  }


  void shoot(boolean fire) {
    if (fire)
      if (cooldown == 0) {
        Grenade b = new Grenade(platform);
        world.addition.add(new GrenadeController(b, platform.controller, multiplier));
        cooldown = firerate;
      }

    if (cooldown != 0)
      cooldown --;
  }
}

