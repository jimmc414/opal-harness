# gamelib

A lightweight game engine library with rendering, physics, input, and audio subsystems.

## Usage

```python
from gamelib import GameEngine, PhysicsBody, draw_sprite

engine = GameEngine(800, 600)
body = PhysicsBody(100, 100, 32, 32)
engine.add_body(body)
engine.update(dt=1/60)
```

## Testing

```bash
pytest tests/
```
