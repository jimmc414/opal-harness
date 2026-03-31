import math


# ---- Rendering ----

class Renderer:
    def __init__(self, width, height):
        self.width = width
        self.height = height
        self.buffer = []

    def render(self):
        output = self.buffer.copy()
        self.buffer.clear()
        return output

    def add_to_buffer(self, item):
        self.buffer.append(item)


def draw_sprite(renderer, sprite_name, x, y):
    item = {"type": "sprite", "name": sprite_name, "x": x, "y": y}
    renderer.add_to_buffer(item)
    return item


def draw_text(renderer, text, x, y, size=16):
    item = {"type": "text", "content": text, "x": x, "y": y, "size": size}
    renderer.add_to_buffer(item)
    return item


def clear_screen(renderer):
    renderer.buffer.clear()


# ---- Physics ----

class PhysicsBody:
    def __init__(self, x, y, width, height, mass=1.0):
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.mass = mass
        self.vx = 0.0
        self.vy = 0.0

    def update(self, dt):
        self.x += self.vx * dt
        self.y += self.vy * dt

    def bounds(self):
        return (self.x, self.y, self.x + self.width, self.y + self.height)


def apply_gravity(body, gravity=9.8, dt=1/60):
    body.vy += gravity * dt


def check_collision(body_a, body_b):
    ax1, ay1, ax2, ay2 = body_a.bounds()
    bx1, by1, bx2, by2 = body_b.bounds()
    return ax1 < bx2 and ax2 > bx1 and ay1 < by2 and ay2 > by1


def resolve_collision(body_a, body_b):
    if not check_collision(body_a, body_b):
        return False
    total_mass = body_a.mass + body_b.mass
    body_a.vx = (body_a.vx * (body_a.mass - body_b.mass) + 2 * body_b.mass * body_b.vx) / total_mass
    body_a.vy = (body_a.vy * (body_a.mass - body_b.mass) + 2 * body_b.mass * body_b.vy) / total_mass
    body_b.vx = (body_b.vx * (body_b.mass - body_a.mass) + 2 * body_a.mass * body_a.vx) / total_mass
    body_b.vy = (body_b.vy * (body_b.mass - body_a.mass) + 2 * body_a.mass * body_a.vy) / total_mass
    return True


# ---- Input ----

class InputHandler:
    def __init__(self):
        self._keys = set()
        self._mouse_x = 0
        self._mouse_y = 0

    def press_key(self, key):
        self._keys.add(key)

    def release_key(self, key):
        self._keys.discard(key)

    def is_key_pressed(self, key):
        return key in self._keys

    def set_mouse(self, x, y):
        self._mouse_x = x
        self._mouse_y = y


def key_pressed(handler, key):
    return handler.is_key_pressed(key)


def mouse_position(handler):
    return (handler._mouse_x, handler._mouse_y)


# ---- Audio ----

class AudioPlayer:
    def __init__(self):
        self.playing = {}
        self.master_volume = 1.0

    def get_playing(self):
        return dict(self.playing)


def play_sound(player, sound_name, volume=1.0, loop=False):
    effective_volume = volume * player.master_volume
    player.playing[sound_name] = {"volume": effective_volume, "loop": loop}
    return True


def stop_sound(player, sound_name):
    if sound_name in player.playing:
        del player.playing[sound_name]
        return True
    return False


def set_volume(player, volume):
    player.master_volume = max(0.0, min(1.0, volume))


# ---- Game Engine (uses all subsystems) ----

class GameEngine:
    def __init__(self, width=800, height=600):
        self.renderer = Renderer(width, height)
        self.input_handler = InputHandler()
        self.audio = AudioPlayer()
        self.bodies = []
        self.running = False

    def add_body(self, body):
        self.bodies.append(body)

    def update(self, dt=1/60):
        for body in self.bodies:
            apply_gravity(body, dt=dt)
            body.update(dt)

        for i in range(len(self.bodies)):
            for j in range(i + 1, len(self.bodies)):
                resolve_collision(self.bodies[i], self.bodies[j])

    def get_state(self):
        return {
            "bodies": len(self.bodies),
            "playing_sounds": len(self.audio.playing),
            "render_buffer": len(self.renderer.buffer),
            "running": self.running,
        }
