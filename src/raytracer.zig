const rl = @import("raylib");
const std = @import("std");

pub fn V3FromColor(src: rl.Color) rl.Vector3 {
    const x: f32 = @floatFromInt(src.r);
    const y: f32 = @floatFromInt(src.g);
    const z: f32 = @floatFromInt(src.b);
    return .{ .x = x / 255, .y = y / 255, .z = z / 255 };
}

pub fn V3ToColor(color: rl.Vector3) rl.Color {
    const r: u8 = @intFromFloat(@max(0, @min(255, color.x * 255)));
    const g: u8 = @intFromFloat(@max(0, @min(255, color.y * 255)));
    const b: u8 = @intFromFloat(@max(0, @min(255, color.z * 255)));
    return .{ .r = r, .g = g, .b = b, .a = 0xff };
}

pub const Light = struct {
    Color: rl.Vector3,
    Position: rl.Vector3,
    Intensity: f32,
};

pub const Material = struct {
    Color: rl.Vector3,
    Especular: f32,
    Refractive_index: f32,
    Texture: ?rl.Image = null,
    Emission: rl.Vector3 = .zero(),
    Propiedades: struct {
        Albedo: f32,
        Especular: f32,
        Reflectividad: f32,
        Transparencia: f32,
    },
};

pub const Intersect = struct {
    Material: Material,
    Distancia: f32,
    Normal: rl.Vector3,
    Punto: rl.Vector3,
    UV: rl.Vector2 = .{ .x = 0, .y = 0 },
};

pub fn sampleMaterialColor(mat: Material, uv: rl.Vector2) rl.Vector3 {
    if (mat.Texture) |tex| {
        const px: i32 = @intFromFloat(std.math.clamp(uv.x, 0.0, 0.999) * @as(f32, @floatFromInt(tex.width)));
        const py: i32 = @intFromFloat(std.math.clamp(1.0 - uv.y, 0.0, 0.999) * @as(f32, @floatFromInt(tex.height)));
        return V3FromColor(tex.getColor(px, py));
    }
    return mat.Color;
}

pub fn sampleSkybox(sky: rl.Image, direction: rl.Vector3) rl.Vector3 {
    const d = direction.normalize();
    const u = (std.math.atan2(d.z, d.x) + std.math.pi) / (2 * std.math.pi);
    const v = std.math.acos(std.math.clamp(d.y, -1, 1)) / std.math.pi;

    const px: i32 = @intFromFloat(std.math.clamp(u, 0.0, 0.999) * @as(f32, @floatFromInt(sky.width)));
    const py: i32 = @intFromFloat(std.math.clamp(v, 0.0, 0.999) * @as(f32, @floatFromInt(sky.height)));

    return V3FromColor(sky.getColor(px, py));
}
