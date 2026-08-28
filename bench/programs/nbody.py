import math


class Body:
    __slots__ = ("x", "y", "z", "vx", "vy", "vz", "mass")

    def __init__(self, x, y, z, vx, vy, vz, mass):
        self.x = x
        self.y = y
        self.z = z
        self.vx = vx
        self.vy = vy
        self.vz = vz
        self.mass = mass


def advance(bodies, dt):
    n = len(bodies)
    for i in range(n):
        bi = bodies[i]
        for j in range(i + 1, n):
            bj = bodies[j]
            dx = bi.x - bj.x
            dy = bi.y - bj.y
            dz = bi.z - bj.z
            dsq = dx * dx + dy * dy + dz * dz
            distance = math.sqrt(dsq)
            mag = dt / (dsq * distance)

            bi.vx -= dx * bj.mass * mag
            bi.vy -= dy * bj.mass * mag
            bi.vz -= dz * bj.mass * mag

            bj.vx += dx * bi.mass * mag
            bj.vy += dy * bi.mass * mag
            bj.vz += dz * bi.mass * mag

    for b in bodies:
        b.x += dt * b.vx
        b.y += dt * b.vy
        b.z += dt * b.vz


def energy(bodies):
    n = len(bodies)
    e = 0.0
    for i in range(n):
        bi = bodies[i]
        e += 0.5 * bi.mass * (bi.vx * bi.vx + bi.vy * bi.vy + bi.vz * bi.vz)
        for j in range(i + 1, n):
            bj = bodies[j]
            dx = bi.x - bj.x
            dy = bi.y - bj.y
            dz = bi.z - bj.z
            distance = math.sqrt(dx * dx + dy * dy + dz * dz)
            e -= (bi.mass * bj.mass) / distance
    return e


def main():
    PI = 3.141592653589793
    SOLAR_MASS = 4.0 * PI * PI
    DAYS_PER_YEAR = 365.24

    bodies = [
        Body(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, SOLAR_MASS),
        Body(
            4.8414314424647209,
            -1.16032004402742839,
            -0.103622044471123109,
            0.00166007664274403694 * DAYS_PER_YEAR,
            0.00769901111281974650 * DAYS_PER_YEAR,
            -0.0000690460016972063023 * DAYS_PER_YEAR,
            0.000954791938424326609 * SOLAR_MASS,
        ),
        Body(
            8.3433664256532493,
            4.12479856412430479,
            -0.403523417114321381,
            -0.00276742510726862411 * DAYS_PER_YEAR,
            0.00499852801234917238 * DAYS_PER_YEAR,
            0.0000230417297573763929 * DAYS_PER_YEAR,
            0.00028588567272224177 * SOLAR_MASS,
        ),
        Body(
            12.894369562139131,
            -15.1111514016986312,
            -0.223307578892655734,
            0.00296460137564761618 * DAYS_PER_YEAR,
            0.0023784717395948095 * DAYS_PER_YEAR,
            -0.0000296589568540237556 * DAYS_PER_YEAR,
            0.0000436624404335156298 * SOLAR_MASS,
        ),
        Body(
            15.3796971148509165,
            -25.9193146099879641,
            0.179258772950371181,
            0.00268067772490024322 * DAYS_PER_YEAR,
            0.00162824170038242295 * DAYS_PER_YEAR,
            -0.000095159225451971587 * DAYS_PER_YEAR,
            0.0000515138902046611451 * SOLAR_MASS,
        ),
    ]

    px = 0.0
    py = 0.0
    pz = 0.0
    for b in bodies:
        px += b.vx * b.mass
        py += b.vy * b.mass
        pz += b.vz * b.mass
    bodies[0].vx = -px / SOLAR_MASS
    bodies[0].vy = -py / SOLAR_MASS
    bodies[0].vz = -pz / SOLAR_MASS

    for _ in range(50000):
        advance(bodies, 0.01)

    final_e = energy(bodies)
    rounded = math.floor(final_e * 10000) / 10000
    print(f"{rounded:g}")


if __name__ == "__main__":
    main()

