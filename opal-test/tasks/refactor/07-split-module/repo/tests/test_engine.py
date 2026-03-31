from gamelib import (
    Renderer, draw_sprite, draw_text, clear_screen,
    PhysicsBody, apply_gravity, check_collision, resolve_collision,
    InputHandler, key_pressed, mouse_position,
    AudioPlayer, play_sound, stop_sound, set_volume,
    GameEngine,
)


# Renderer tests
def test_draw_sprite():
    r = Renderer(800, 600)
    item = draw_sprite(r, "player", 100, 200)
    assert item["type"] == "sprite"
    assert item["name"] == "player"


def test_draw_text():
    r = Renderer(800, 600)
    item = draw_text(r, "Score: 0", 10, 10, size=24)
    assert item["content"] == "Score: 0"
    assert item["size"] == 24


def test_render_clears_buffer():
    r = Renderer(800, 600)
    draw_sprite(r, "enemy", 0, 0)
    output = r.render()
    assert len(output) == 1
    assert len(r.buffer) == 0


def test_clear_screen():
    r = Renderer(800, 600)
    draw_sprite(r, "bg", 0, 0)
    clear_screen(r)
    assert len(r.buffer) == 0


# Physics tests
def test_physics_body_update():
    body = PhysicsBody(0, 0, 10, 10)
    body.vx = 100
    body.vy = 50
    body.update(0.1)
    assert body.x == 10.0
    assert body.y == 5.0


def test_apply_gravity():
    body = PhysicsBody(0, 0, 10, 10)
    apply_gravity(body, gravity=10, dt=1.0)
    assert body.vy == 10.0


def test_check_collision():
    a = PhysicsBody(0, 0, 10, 10)
    b = PhysicsBody(5, 5, 10, 10)
    assert check_collision(a, b) is True


def test_no_collision():
    a = PhysicsBody(0, 0, 10, 10)
    b = PhysicsBody(20, 20, 10, 10)
    assert check_collision(a, b) is False


def test_resolve_collision():
    a = PhysicsBody(0, 0, 10, 10, mass=1.0)
    b = PhysicsBody(5, 5, 10, 10, mass=1.0)
    a.vx = 10
    resolved = resolve_collision(a, b)
    assert resolved is True


# Input tests
def test_key_press():
    handler = InputHandler()
    handler.press_key("space")
    assert key_pressed(handler, "space") is True
    assert key_pressed(handler, "enter") is False


def test_key_release():
    handler = InputHandler()
    handler.press_key("space")
    handler.release_key("space")
    assert key_pressed(handler, "space") is False


def test_mouse_position():
    handler = InputHandler()
    handler.set_mouse(100, 200)
    pos = mouse_position(handler)
    assert pos == (100, 200)


# Audio tests
def test_play_sound():
    player = AudioPlayer()
    play_sound(player, "explosion", volume=0.8)
    playing = player.get_playing()
    assert "explosion" in playing


def test_stop_sound():
    player = AudioPlayer()
    play_sound(player, "music")
    assert stop_sound(player, "music") is True
    assert stop_sound(player, "music") is False


def test_set_volume():
    player = AudioPlayer()
    set_volume(player, 0.5)
    assert player.master_volume == 0.5
    set_volume(player, -1)
    assert player.master_volume == 0.0
    set_volume(player, 2)
    assert player.master_volume == 1.0


# GameEngine tests
def test_engine_init():
    engine = GameEngine()
    state = engine.get_state()
    assert state["bodies"] == 0
    assert state["running"] is False


def test_engine_add_body():
    engine = GameEngine()
    engine.add_body(PhysicsBody(0, 0, 10, 10))
    assert engine.get_state()["bodies"] == 1


def test_engine_update():
    engine = GameEngine()
    body = PhysicsBody(0, 0, 10, 10)
    engine.add_body(body)
    engine.update(dt=0.1)
    assert body.y > 0  # gravity applied
