const std = @import("std");
const rl = @import("raylib");
const Intersect = @import("raytracer.zig").Intersect;
const Material = @import("raytracer.zig").Material;

pub const Cube = struct {
    center: rl.Vector3,
    half_size: rl.Vector3, // mitad del ancho/alto/profundidad en cada eje
    material: Material,

    pub fn intersect(self: Cube, origin: rl.Vector3, direction: rl.Vector3) ?Intersect {
        const bmin = self.center.subtract(self.half_size);
        const bmax = self.center.add(self.half_size);

        const o = [3]f32{ origin.x, origin.y, origin.z };
        const d = [3]f32{ direction.x, direction.y, direction.z };
        const bmin_a = [3]f32{ bmin.x, bmin.y, bmin.z };
        const bmax_a = [3]f32{ bmax.x, bmax.y, bmax.z };

        var t_min: f32 = -std.math.floatMax(f32);
        var t_max: f32 = std.math.floatMax(f32);
        var hit_axis: usize = 0;
        var hit_sign: f32 = -1;

        for (0..3) |i| {
            const inv_d = 1.0 / d[i];
            var t0 = (bmin_a[i] - o[i]) * inv_d;
            var t1 = (bmax_a[i] - o[i]) * inv_d;
            var sign: f32 = -1;

            if (inv_d < 0) {
                std.mem.swap(f32, &t0, &t1);
                sign = 1;
            }

            if (t0 > t_min) {
                t_min = t0;
                hit_axis = i;
                hit_sign = sign;
            }
            if (t1 < t_max) t_max = t1;

            if (t_min > t_max) return null;
        }

        if (t_min < 0.0001) return null; // el cubo está detrás del rayo

        const point = origin.add(direction.scale(t_min));

        var normal = rl.Vector3.zero();
        switch (hit_axis) {
            0 => normal.x = hit_sign,
            1 => normal.y = hit_sign,
            2 => normal.z = hit_sign,
            else => unreachable,
        }

        return .{
            .Material = self.material,
            .Distancia = t_min,
            .Normal = normal,
            .Punto = point,
        };
    }
};
