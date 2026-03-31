#!/usr/bin/env bash
set -euo pipefail
cd "$WORK_DIR"

PASS=0
FAIL=0

run_check() {
    local description="$1"
    shift
    if "$@" > /dev/null 2>&1; then
        echo "PASS: $description"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $description"
        FAIL=$((FAIL + 1))
    fi
}

# 1. All existing tests pass
run_check "All existing tests pass" python3 -m pytest tests/ -x -q

# 2. gamelib/rendering.py exists
run_check "rendering.py exists" test -f gamelib/rendering.py

# 3. gamelib/physics.py exists
run_check "physics.py exists" test -f gamelib/physics.py

# 4. gamelib/input.py exists
run_check "input.py exists" test -f gamelib/input.py

# 5. gamelib/audio.py exists
run_check "audio.py exists" test -f gamelib/audio.py

# 6. All original imports still work via 'from gamelib import ...'
run_check "All names importable from gamelib" python3 -c "
from gamelib import (
    Renderer, draw_sprite, draw_text, clear_screen,
    PhysicsBody, apply_gravity, check_collision, resolve_collision,
    InputHandler, key_pressed, mouse_position,
    AudioPlayer, play_sound, stop_sound, set_volume,
    GameEngine,
)
"

# 7. engine.py either doesn't exist or is under 50 lines (not a monolith)
run_check "engine.py is not a monolith" python3 -c "
import os
engine_path = 'gamelib/engine.py'
if not os.path.exists(engine_path):
    pass  # removed entirely, that's fine
else:
    with open(engine_path) as f:
        lines = [l for l in f.readlines() if l.strip() and not l.strip().startswith('#')]
    assert len(lines) < 50, f'engine.py has {len(lines)} non-blank non-comment lines (expected < 50)'
"

# 8. Renderer and draw_sprite importable from gamelib.rendering
run_check "Renderer importable from gamelib.rendering" python3 -c "
from gamelib.rendering import Renderer, draw_sprite, draw_text, clear_screen
r = Renderer(800, 600)
item = draw_sprite(r, 'test', 0, 0)
assert item['type'] == 'sprite'
"

# 9. PhysicsBody and check_collision importable from gamelib.physics
run_check "PhysicsBody importable from gamelib.physics" python3 -c "
from gamelib.physics import PhysicsBody, apply_gravity, check_collision, resolve_collision
a = PhysicsBody(0, 0, 10, 10)
b = PhysicsBody(5, 5, 10, 10)
assert check_collision(a, b) is True
"

# 10. InputHandler importable from gamelib.input
run_check "InputHandler importable from gamelib.input" python3 -c "
from gamelib.input import InputHandler, key_pressed, mouse_position
h = InputHandler()
h.press_key('space')
assert key_pressed(h, 'space') is True
"

# 11. AudioPlayer importable from gamelib.audio
run_check "AudioPlayer importable from gamelib.audio" python3 -c "
from gamelib.audio import AudioPlayer, play_sound, stop_sound, set_volume
p = AudioPlayer()
play_sound(p, 'test')
assert 'test' in p.get_playing()
"

# 12. GameEngine still functional (create, add body, update, get_state)
run_check "GameEngine still functional end-to-end" python3 -c "
from gamelib import GameEngine, PhysicsBody
engine = GameEngine(800, 600)
body = PhysicsBody(0, 0, 10, 10)
engine.add_body(body)
engine.update(dt=0.1)
state = engine.get_state()
assert state['bodies'] == 1
assert body.y > 0, 'gravity should have moved body down'
"

# 13. resolve_collision works correctly across modules (calls check_collision internally)
run_check "resolve_collision cross-module call works" python3 -c "
from gamelib.physics import PhysicsBody, resolve_collision
a = PhysicsBody(0, 0, 10, 10, mass=1.0)
b = PhysicsBody(5, 5, 10, 10, mass=1.0)
a.vx = 10.0
result = resolve_collision(a, b)
assert result is True, 'collision should resolve'
assert a.vx != 10.0, 'velocity should have changed after collision'
"

# 14. import math only appears in modules that actually use it
run_check "math import only in modules that use it" python3 -c "
import os, re
for fname in os.listdir('gamelib'):
    if not fname.endswith('.py'):
        continue
    path = os.path.join('gamelib', fname)
    with open(path) as f:
        source = f.read()
    if re.search(r'^import math', source, re.MULTILINE) or re.search(r'from math import', source, re.MULTILINE):
        # Check if math is actually used beyond the import line
        lines = [l for l in source.splitlines() if not l.startswith('import math') and not l.startswith('from math')]
        uses_math = any('math.' in l for l in lines)
        assert uses_math, f'{fname} imports math but never uses it'
"

echo ""
echo "Results: $PASS passed, $FAIL failed out of $((PASS + FAIL)) checks"
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
