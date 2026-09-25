const std = @import("std");
const builtin = @import("builtin");

const rl = @import("raylib");
const Framebuffer = @import("framebuffer.zig").Framebuffer;
const Forma = @import("formas.zig").Forma;
const Camera = @import("camera.zig").Camera;
const Light = @import("raytracer.zig").Light;
const Intersect = @import("raytracer.zig").Intersect;
const Material = @import("raytracer.zig").Material;

const htmlColor = @import("cute_colors.zig").htmlColor;
const V3FromColor = @import("raytracer.zig").V3FromColor;
const V3ToColor = @import("raytracer.zig").V3ToColor;

const Clock = std.Io.Clock.real;

const width = 960;
const height = 600;

const block_sz = 100;

pub fn main() !void {
    var alloc = switch (builtin.mode) {
        .Debug, .ReleaseSafe => std.heap.DebugAllocator(.{}).init,
        .ReleaseFast, .ReleaseSmall => std.heap.smp_allocator,
    };
    const gpa: std.mem.Allocator = switch (builtin.mode) {
        .Debug, .ReleaseSafe => alloc.allocator(),
        .ReleaseFast, .ReleaseSmall => std.heap.smp_allocator,
    };
    defer switch (builtin.mode) {
        .Debug, .ReleaseSafe => _ = alloc.deinit(),
        .ReleaseFast, .ReleaseSmall => {},
    };

    var threaded: std.Io.Threaded = .init(gpa, .{});
    const io = threaded.io();
    var framebuffer = Framebuffer.init(width, height, .black, .white);

    rl.initWindow(width, height, "Raytracer!!!");
    rl.setTraceLogLevel(.warning);
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var last_frame_time = Clock.now(io);
    var delta: i64 = 1;

    const mat_piedra = Material{
        .Color = V3FromColor(htmlColor("#999")),
        .Texture = try rl.loadImage("assets/textures/stone.png"),
        .Propiedades = .{
            .Albedo = 0.8,
            .Especular = 0.2,
            .Reflectividad = 0,
            .Transparencia = 0,
        },
        .Especular = 8,
        .Refractive_index = 0,
    };

    const mat_madera = Material{
        .Color = V3FromColor(htmlColor("#8b5a2b")),
        .Texture = try rl.loadImage("assets/textures/wood.png"),
        .Propiedades = .{
            .Albedo = 0.6,
            .Especular = 0.3,
            .Reflectividad = 0,
            .Transparencia = 0,
        },
        .Especular = 15,
        .Refractive_index = 0,
    };

    const mat_metal = Material{
        .Color = V3FromColor(htmlColor("#ccc")),
        .Texture = try rl.loadImage("assets/textures/metal.png"),
        .Propiedades = .{
            .Albedo = 0.2,
            .Especular = 0.8,
            .Reflectividad = 0.6,
            .Transparencia = 0,
        },
        .Especular = 90,
        .Refractive_index = 0,
    };

    const mat_vidrio = Material{
        .Color = V3FromColor(htmlColor("#dff")),
        .Texture = try rl.loadImage("assets/textures/glass.png"),
        .Propiedades = .{
            .Albedo = 0.1,
            .Especular = 0.9,
            .Reflectividad = 0.1,
            .Transparencia = 0.85,
        },
        .Especular = 120,
        .Refractive_index = 1.5,
    };

    const mat_pasto = Material{
        .Color = V3FromColor(htmlColor("#4a7")),
        .Texture = try rl.loadImage("assets/textures/grass.png"),
        .Propiedades = .{
            .Albedo = 0.9,
            .Especular = 0.05,
            .Reflectividad = 0,
            .Transparencia = 0,
        },
        .Especular = 4,
        .Refractive_index = 0,
    };

    const lights = [_]Light{
        .{
            .Color = V3FromColor(htmlColor("#f00")),
            .Intensity = 1,
            .Position = .{ .x = 5, .y = 100, .z = 15 },
        },
        .{
            .Color = V3FromColor(htmlColor("#fff")),
            .Intensity = 1,
            .Position = .{ .x = 0, .y = 0, .z = -250 },
        },
    };

    const cameraDistance = 100;
    var camera: Camera = .init(.{
        .x = 0,
        .y = 0,
        .z = cameraDistance,
    }, .zero());

    const cameraTurnSpeed: f32 = std.math.pi / 2.0;
    var camera_x_angle: f32 = std.math.pi;
    var camera_y_angle: f32 = 0;

    const camera_y_angle_max = std.math.pi / 4.0;
    const camera_y_angle_min = -camera_y_angle_max;

    var diorama_angle: f32 = 0;
    while (!rl.windowShouldClose()) {
        defer {
            const now = Clock.now(io);
            delta = last_frame_time.durationTo(now).toMicroseconds();
            last_frame_time = now;
        }
        framebuffer.clear();

        const dt: f32 = @as(f32, @floatFromInt(delta)) / 1_000_000;
        diorama_angle += 0.3 * dt;
        const cos_a = @cos(diorama_angle);
        const sin_a = @sin(diorama_angle);

        const spheres = [_]Forma{
            .{ .Cube = .{
                .center = rotateXZ(.{ .x = 0, .y = -12, .z = -40 }, cos_a, sin_a),
                .half_size = .{ .x = 30, .y = 2, .z = 30 },
                .material = mat_pasto,
            } },
            .{ .Cube = .{
                .center = rotateXZ(.{ .x = 0, .y = -4, .z = -40 }, cos_a, sin_a),
                .half_size = .{ .x = 8, .y = 6, .z = 8 },
                .material = mat_piedra,
            } },
            .{ .Cube = .{
                .center = rotateXZ(.{ .x = 0, .y = 3, .z = -40 }, cos_a, sin_a),
                .half_size = .{ .x = 9, .y = 1, .z = 9 },
                .material = mat_madera,
            } },
            .{ .Cube = .{
                .center = rotateXZ(.{ .x = 16, .y = -6, .z = -35 }, cos_a, sin_a),
                .half_size = .{ .x = 2, .y = 4, .z = 2 },
                .material = mat_metal,
            } },
            .{ .Cube = .{
                .center = rotateXZ(.{ .x = -14, .y = -8, .z = -25 }, cos_a, sin_a),
                .half_size = .{ .x = 4, .y = 2, .z = 4 },
                .material = mat_vidrio,
            } },
        };

        if (rl.isKeyDown(.a)) {
            camera_x_angle += cameraTurnSpeed * dt;
        }
        if (rl.isKeyDown(.d)) {
            camera_x_angle -= cameraTurnSpeed * dt;
        }
        if (rl.isKeyDown(.w)) {
            camera_y_angle += cameraTurnSpeed * dt;
            camera_y_angle = @max(camera_y_angle_min, @min(camera_y_angle_max, camera_y_angle));
        }
        if (rl.isKeyDown(.s)) {
            camera_y_angle -= cameraTurnSpeed * dt;
            camera_y_angle = @max(camera_y_angle_min, @min(camera_y_angle_max, camera_y_angle));
        }

        camera.Postition.x = @cos(camera_x_angle) * cameraDistance;
        camera.Postition.y = @sin(camera_y_angle) * cameraDistance;
        camera.Postition.z = @sin(camera_x_angle) * cameraDistance;

        camera.lookAt(.zero());

        try render(&framebuffer, &spheres, &lights, camera);

        try framebuffer.swap_buffers();
    }
}

fn render(target: *Framebuffer, objects: []const Forma, lights: []const Light, camera: Camera) !void {
    const width_f32: f32 = @floatFromInt(target.width);
    const height_f32: f32 = @floatFromInt(target.height);

    const aspect_ratio = width_f32 / height_f32;
    const FOV = std.math.pi / 3.0;
    const perspective_scale = @tan(FOV * 0.5);

    for (0..height) |screen_y| {
        for (0..width) |screen_x| {
            const x_f32: f32 = @floatFromInt(screen_x);
            const y_f32: f32 = @floatFromInt(screen_y);

            const x_minus1_to_1 = (x_f32 * 2) / width_f32 - 1;
            const y_minus1_to_1 = 1 - (y_f32 * 2) / height_f32;

            const x_direction = x_minus1_to_1 * aspect_ratio * perspective_scale;
            const y_direction = y_minus1_to_1 * perspective_scale;

            const direction_from_camera = (rl.Vector3{
                .x = x_direction,
                .y = y_direction,
                .z = 1,
            }).normalize();

            const direction = rl.Vector3{
                .x = direction_from_camera.x * camera.Right.x + direction_from_camera.y * camera.Up.x + direction_from_camera.z * camera.Forward.x,
                .y = direction_from_camera.x * camera.Right.y + direction_from_camera.y * camera.Up.y + direction_from_camera.z * camera.Forward.y,
                .z = direction_from_camera.x * camera.Right.z + direction_from_camera.y * camera.Up.z + direction_from_camera.z * camera.Forward.z,
            };

            const col = cast_ray(camera.Postition, direction, objects, lights, 5);
            target.set_current_color(V3ToColor(col));
            try target.set_pixel(@intCast(screen_x), @intCast(screen_y));
        }
    }
}

fn refract(incident: rl.Vector3, normal: rl.Vector3, refractive_index: f32) ?rl.Vector3 {
    var cosi = incident.dotProduct(normal);

    var etai: f32 = 1;
    var etat = refractive_index;
    var n = normal;

    if (cosi > 0) {
        std.mem.swap(f32, &etai, &etat);
        n = n.scale(-1);
    } else {
        cosi = -cosi;
    }

    const eta = etai / etat;
    const k = 1 - eta * eta * (1 - cosi * cosi);

    if (k < 0) {
        return null;
    } else {
        return (incident.scale(eta).add(n.scale(eta * cosi - @sqrt(k)))).normalize();
    }
}

fn cast_ray(origin: rl.Vector3, direction: rl.Vector3, objects: []const Forma, lights: []const Light, max_recursion: usize) rl.Vector3 {
    var closest_hit: ?Intersect = null;
    var z_buffer: f32 = std.math.floatMax(f32);
    for (objects) |object| {
        const hit = object.intersect(
            origin,
            direction,
        ) orelse continue;

        if (hit.Distancia < z_buffer) {
            z_buffer = hit.Distancia;

            closest_hit = hit;
        }
    }

    if (closest_hit) |hit| {
        const mat = hit.Material;
        var color: rl.Vector3 = .zero();

        // Desde el punto a la cámara
        const view_direction = direction.scale(-1);

        if (mat.Propiedades.Reflectividad > 0) {
            if (max_recursion > 0) {
                const reflect_direction = rl.Vector3{ .x = 0, .y = 1, .z = 0 };
                const new_og = hit.Punto; // Esto puede hacer que topemos con la misma figura
                // Eso es malo
                const reflect_color = cast_ray(new_og, reflect_direction, objects, lights, max_recursion - 1);
                color = color.add(reflect_color.scale(mat.Propiedades.Reflectividad));
            } else {
                // Refleja el fondo
                color = color.add(.zero());
            }
        }

        if (mat.Propiedades.Transparencia > 0) {
            if (max_recursion > 0) {
                if (refract(direction, hit.Normal, mat.Refractive_index)) |refract_direction| {
                    const new_og = hit.Punto; // Esto puede hacer que topemos con la misma figura
                    // Eso es malo
                    const refract_color = cast_ray(new_og, refract_direction, objects, lights, max_recursion - 1);
                    color = color.add(refract_color.scale(mat.Propiedades.Transparencia));
                } else {
                    const reflect_direction = rl.Vector3{ .x = 0, .y = 1, .z = 0 };
                    const new_og = hit.Punto; // Esto puede hacer que topemos con la misma figura
                    // Eso es malo
                    const reflect_color = cast_ray(new_og, reflect_direction, objects, lights, max_recursion - 1);
                    color = color.add(reflect_color.scale(mat.Propiedades.Reflectividad));
                }
            } else {
                // Refleja el fondo
                color = color.add(.zero());
            }
        }

        const ambient_intensity: f32 = 0.15;
        const base_color = @import("raytracer.zig").sampleMaterialColor(mat, hit.UV);
        color = color.add(base_color.scale(ambient_intensity));

        for (lights) |light| {
            if (obscured(hit.Punto, light, objects))
                continue;

            const light_dir = (light.Position.subtract(hit.Punto)).normalize();

            const diffuse_intensity = @max(0, hit.Normal.dotProduct(light_dir)) * light.Intensity;
            //const base_color = @import("raytracer.zig").sampleMaterialColor(mat, hit.UV);
            const diffuse = base_color.scale(diffuse_intensity);

            const reflection_dir = hit.Normal.scale(2 * hit.Normal.dotProduct(light_dir)).subtract(light_dir).normalize();
            const specular_intensity = std.math.pow(f32, @max(0, reflection_dir.dotProduct(view_direction)), mat.Especular) * light.Intensity;
            const specular = light.Color.scale(specular_intensity);

            color = color.add(diffuse.scale(mat.Propiedades.Albedo));
            color = color.add(specular.scale(mat.Propiedades.Especular));
        }

        return color;
    } else return .zero();
}

fn obscured(origin: rl.Vector3, light: Light, objects: []const Forma) bool {
    const light_vec = light.Position.subtract(origin);
    const light_distance = light_vec.length();
    const light_dir = light_vec.normalize();

    const shadow_origin = origin.add(light_dir.scale(0.001));

    for (objects) |object| {
        if (object.intersect(shadow_origin, light_dir)) |hit| {
            if (hit.Distancia < light_distance) {
                return true;
            }
        }
    }

    return false;
}

fn rotateXZ(p: rl.Vector3, cos_a: f32, sin_a: f32) rl.Vector3 {
    return .{
        .x = p.x * cos_a - p.z * sin_a,
        .y = p.y,
        .z = p.x * sin_a + p.z * cos_a,
    };
}
