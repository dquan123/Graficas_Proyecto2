const Sphere = @import("sphere.zig").Sphere;
const Cube = @import("cube.zig").Cube;
const Intersect = @import("raytracer.zig").Intersect;
const rl = @import("raylib");

const tipo = enum {
    Sphere,
    Cube,
};

pub const Forma = union(tipo) {
    Sphere: Sphere,
    Cube: Cube,

    pub fn intersect(self: Forma, origin: rl.Vector3, direction: rl.Vector3) ?Intersect {
        return switch (self) {
            .Sphere => |a| a.intersect(origin, direction),
            .Cube => |a| a.intersect(origin, direction),
        };
    }
};
