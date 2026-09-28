# Proyecto 2: Raytracing

Diorama 3D hecho con un raytracer en Zig 0.16. Solo usa raylib para la ventana y para mostrar el framebuffer, y todo el cálculo de luz, reflejos y refracción se hace en CPU. La escena es una casita hecha con cubos texturizados sobre una base de pasto, con un skybox de fondo.

## Autor
Diego Quan (24336)

## Cómo correrlo

```bash
zig build run -Doptimize=ReleaseFast
```

Usa siempre `-Doptimize=ReleaseFast`. Sin ese flag el render es muchísimo más lento. El primer frame puede tardar unos segundos.

## Controles

| Tecla | Acción |
|---|---|
| **A / D** | Orbitar la cámara alrededor del diorama |
| **W / S** | Subir / bajar la cámara |
| **↑ / ↓** | Acercar / alejar la cámara (zoom) |

## Objetivos implementados

| Objetivo | Puntos | Cómo se implementó |
|---|---|---|
| Cámara que se acerca y aleja | 10 | La distancia de la cámara orbital se controla con las flechas ↑/↓ y se limita a un rango. |
| Materiales diferentes (máx. 25) | 25 | Piedra, madera, metal, vidrio y pasto. Cada uno tiene su textura y sus propios valores de albedo, especular, reflectividad y transparencia. |
| Refracción | 10 | El vidrio usa la ley de Snell con índice de refracción 1.5, incluyendo reflexión interna total. |
| Reflexión | 5 | El metal refleja el entorno con la fórmula de reflexión sobre la normal. |
| Sombras | 5 | Se lanza un rayo de sombra hacia cada luz. |
| Materiales translúcidos o reflectivos con color | 15 | El vidrio verde esmeralda tiñe lo que refracta y refleja multiplicando por su color. |
| Materiales que brillan | 20 | El cristal cian tiene emisión propia y se ve brillante aunque esté sin luz directa. |
| Skybox | 20 | Imagen panorámica. Se ve de fondo y también en los reflejos. |
| **Total** | **110** | |

## Detalles técnicos

- **Cubos:** la intersección rayo-cubo usa el método de "slabs". Las coordenadas UV se calculan por cara para poder texturizar.
- **Iluminación:** luz ambiental, difusa y especular (modelo Phong), con dos luces puntuales.
- **Recursión:** los rayos de reflexión y refracción rebotan hasta 5 veces.

## Estructura

- `src/main.zig`: escena, cámara y la función `cast_ray`
- `src/cube.zig` y `src/sphere.zig`: intersecciones de cada forma
- `src/formas.zig`: unión que agrupa las formas
- `src/raytracer.zig`: materiales, luces, intersecciones, texturas y skybox
- `src/camera.zig`: cámara con base ortonormal
- `assets/textures/`: texturas y skybox

## Video

[Pega aquí el link o el GIF del video]
