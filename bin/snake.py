#!/usr/bin/env python3

import argparse
import random
import sys
import time
from collections import deque
from dataclasses import dataclass
from enum import Enum
from typing import Self

import pygame


class Direction(Enum):
	UP = 1
	DOWN = 2
	LEFT = 3
	RIGHT = 4


type Rgb = tuple[int, int, int]


def now_ms() -> float:
	"""Returns monotonic time in milliseconds for all game timing."""
	return time.monotonic() * 1000


@dataclass(frozen=True)
class GameConfig:
	"""Immutable configuration; grid_width/grid_height derived from window + grid_size."""

	window_width: int = 800
	window_height: int = 600
	grid_size: int = 20
	fps: int = 60
	movement_divisor: int = 6
	initial_snake_length: int = 3
	lethal_walls: bool = True
	snake_color: tuple[int, int, int] = (0x00, 0xFF, 0x00)
	snake_dead_color: tuple[int, int, int] = (0x02, 0x56, 0x19)  # darkened green
	background_color: tuple[int, int, int] = (0x00, 0x00, 0x00)
	font_color: tuple[int, int, int] = (0xFF, 0xFF, 0xFF)
	invincibility_duration: int = 5000
	slow_duration: int = 5000
	speed_duration: int = 5000
	slow_factor: int = 3
	speed_factor: int = 3

	@property
	def grid_width(self) -> int:
		return self.window_width // self.grid_size

	@property
	def grid_height(self) -> int:
		return self.window_height // self.grid_size


class FoodType(Enum):
	"""Enum defining all food types and their stats"""

	# Regular foods (points)
	RED = ("red", (255, 0, 0), 1, None)
	ORANGE = ("orange", (0xFF, 0xAA, 0x00), 3, None)
	BROWN = ("brown", (0x56, 0x30, 0x02), -1, None)

	# Power-ups (no points, effects only)
	BLUE = ("blue", (0x33, 0x33, 0xFF), 0, "invincibility")
	WHITE = ("white", (0xDD, 0xDD, 0xDD), 0, "slow")
	GRAY = ("gray", (0x33, 0x33, 0x33), 0, "speed")

	def __init__(self, name: str, color: Rgb, points: int, effect: str | None):
		self.food_name = name
		self.color = color
		self.points = points
		self.effect = effect

	@classmethod
	def get_regular_weights(cls) -> list[tuple["FoodType", int]]:
		"""Return regular food type distribution: RED 80%, ORANGE 15%, BROWN 5%"""
		return [(cls.RED, 80), (cls.ORANGE, 15), (cls.BROWN, 5)]

	@classmethod
	def get_powerup_weights(cls) -> list[tuple["FoodType", int]]:
		"""Return power-up food type distribution"""
		return [(cls.BLUE, 25), (cls.WHITE, 35), (cls.GRAY, 40)]


class BaseFood:  # was @dataclass — overrides __init__, auto-__eq__ incorrectly compares by mutation-prone attrs
	"""Base class for all food"""

	effect: str | None
	position: tuple[int, int]
	color: Rgb = (255, 0, 0)
	points: int = 0

	def __init__(
		self,
		config: GameConfig,
		color: Rgb | None = None,
		position: tuple[int, int] | None = None,
		points: int = 0,
		effect: str | None = None,
	) -> None:
		# self.position: tuple[int, int]
		if color:
			self.color = color

		self.points = points
		self.effect = effect
		if position:
			self.position = position
		else:
			self.randomize_position(config.grid_width, config.grid_height)

	def randomize_position(self, grid_width: int, grid_height: int) -> None:
		self.position = (
			random.randint(0, grid_width - 1),
			random.randint(0, grid_height - 1),
		)

	def apply_effect(self, game: "Game") -> None:
		game.score += self.points
		now = game._effective_time_ms()

		if self.effect == "invincibility":
			game.invincible_until = now + game.config.invincibility_duration
		elif self.effect == "slow":
			game.slow_until = now + game.config.slow_duration
			game.update_movement_divisor(game.config.slow_factor)
		elif self.effect == "speed":
			game.speed_until = now + game.config.speed_duration
			game.update_movement_divisor(1.0 / game.config.speed_factor)


@dataclass
class FloatingText:
	"""On-screen floating text that rises and fades"""

	x: float
	y: float
	text: str
	color: Rgb
	lifetime: int
	birth: float
	velocity_y: float = -0.2

	@classmethod
	def new(
		cls,
		grid_size: int,
		food: BaseFood,
		duration_ms: int = 1000,
	) -> Self | None:
		text = None

		if food.points == 0:
			text = food.effect
		elif food.points > 0:
			# if food.points != 1:

			text = f"+{food.points}"
		elif food.points < 0:
			text = str(food.points)

		if text is None:
			return None

		return cls(
			food.position[0] * grid_size,
			food.position[1] * grid_size,
			text,
			food.color,
			lifetime=duration_ms,
			birth=now_ms(),
		)

	def update(self, delta_ms: float) -> None:
		self.y += self.velocity_y * delta_ms

	def get_alpha(self) -> int:
		age = now_ms() - self.birth
		if age >= self.lifetime:
			return 0
		# Fade out in last 30% of lifetime
		fade_start = self.lifetime * 0.7
		if age < fade_start:
			return 255
		return int(255 * (1.0 - (age - fade_start) / (self.lifetime - fade_start)))

	def is_alive(self) -> bool:
		return (now_ms() - self.birth) < self.lifetime


class RegularFood(BaseFood):
	"""Regular food that gives points (no effects)"""

	def __init__(
		self,
		config: "GameConfig",
		position: tuple[int, int] | None = None,
		food_type: FoodType | None = None,
	) -> None:
		if food_type is None:
			food_type = self._roll_food_type()
		super().__init__(
			config=config,
			position=position,
			color=food_type.color,
			points=food_type.points,
			effect=food_type.effect,
		)

	@classmethod
	def _roll_food_type(cls) -> FoodType:
		"""Roll for food type: 80% RED, 15% ORANGE, 5% BROWN"""
		choices, weights = zip(*FoodType.get_regular_weights())
		return random.choices(choices, weights=weights, k=1)[0]


class PowerUpFood(BaseFood):
	"""Power-up food that gives temporary effects (no points)"""

	def __init__(
		self, config: "GameConfig", position: tuple[int, int] | None = None
	) -> None:
		food_type = PowerUpFood._roll_powerup_type()
		super().__init__(
			config=config,
			position=position,
			color=food_type.color,
			points=0,
			effect=food_type.effect,
		)

	@classmethod
	def _roll_powerup_type(cls) -> FoodType:
		"""Roll for power-up type: BLUE 25%, WHITE 35%, GRAY 40%"""
		choices, weights = zip(*FoodType.get_powerup_weights())
		return random.choices(choices, weights=weights, k=1)[0]


@dataclass
class ActiveEffect:
	"""An effect that's currently active with its remaining progress"""

	name: str
	color: Rgb
	bar_color: Rgb  # often slightly lighter for visibility on dark bg
	progress: float  # 0.0 to 1.0


class Snake:
	def __init__(self, start_x: int, start_y: int, config: GameConfig) -> None:
		self.positions: list[tuple[int, int]] = []
		# Random initial direction
		self.direction: Direction = random.choice(list(Direction))
		self.next_direction: Direction = self.direction
		self.grow_pending: int = 0
		self.config = config
		for i in range(config.initial_snake_length):
			offset_x, offset_y = {
				Direction.UP: (0, 1),
				Direction.DOWN: (0, -1),
				Direction.LEFT: (1, 0),
				Direction.RIGHT: (-1, 0),
			}[self.direction]
			self.positions.append((start_x + offset_x * i, start_y + offset_y * i))

	def change_direction(self, new_direction: Direction) -> None:
		if (
			(new_direction == Direction.UP and self.direction != Direction.DOWN)
			or (new_direction == Direction.DOWN and self.direction != Direction.UP)
			or (new_direction == Direction.LEFT and self.direction != Direction.RIGHT)
			or (new_direction == Direction.RIGHT and self.direction != Direction.LEFT)
		):
			self.next_direction = new_direction

	def move(self, lethal_walls: bool, invincible: bool) -> bool | None:
		self.direction = self.next_direction
		head_x, head_y = self.positions[0]

		if self.direction == Direction.UP:
			head_y -= 1
		elif self.direction == Direction.DOWN:
			head_y += 1
		elif self.direction == Direction.LEFT:
			head_x -= 1
		elif self.direction == Direction.RIGHT:
			head_x += 1

		# Wall collision
		hit_wall = False
		if head_x < 0 or head_x >= self.config.grid_width:
			hit_wall = True
		if head_y < 0 or head_y >= self.config.grid_height:
			hit_wall = True

		if hit_wall:
			if lethal_walls and not invincible:
				return True
			# Wrap when invincible (or non-lethal)
			head_x %= self.config.grid_width
			head_y %= self.config.grid_height

		self.positions.insert(0, (head_x, head_y))

		if self.grow_pending > 0:
			self.grow_pending -= 1
		else:
			self.positions.pop()

		return False

	def check_collision(self) -> bool:
		return len(self.positions) != len(set(self.positions))

	def get_head_position(self) -> tuple[int, int]:
		return self.positions[0]

	def grow(self, amount: int) -> None:
		"""Grow or shrink snake by amount
		- positive: queue growth segments at head
		- negative: remove segments from tail (min 1)
		"""
		if amount > 0:
			self.grow_pending += amount
		elif amount < 0:
			shrink = min(-amount, len(self.positions) - 1)
			for _ in range(shrink):
				if len(self.positions) > 1:
					self.positions.pop()


class Game:
	config: GameConfig
	snake: Snake
	screen: pygame.Surface
	current_divisor: int
	frame_count: int = 0
	score: int = 0
	game_over: bool = False
	paused: bool = False
	invincible_until: float = 0
	slow_until: float = 0
	speed_until: float = 0
	clock: pygame.time.Clock = pygame.time.Clock()
	font: pygame.font.Font
	small_font: pygame.font.Font
	large_font: pygame.font.Font
	foods: list[BaseFood] = []
	input_queue: deque[Direction] = deque()
	floating_texts: list[FloatingText] = []
	_pause_start_ms: float | None = None
	_total_paused_offset_ms: float = 0.0

	def __init__(self, config: GameConfig) -> None:
		pygame.init()
		self.config = config
		self.screen = pygame.display.set_mode(
			(config.window_width, config.window_height)
		)
		pygame.display.set_caption("Snake Game")
		self.font = pygame.font.SysFont("sans-serif", 24)
		self.small_font = pygame.font.SysFont("sans-serif", 16)
		try:
			self.large_font = pygame.font.Font(None, 72)
		except pygame.error:
			self.large_font = pygame.font.SysFont("sans-serif", 72)
		start_x = config.grid_width // 2
		start_y = config.grid_height // 2
		self.snake = Snake(start_x, start_y, config)

		self.current_divisor = config.movement_divisor
		self.spawn_initial_food()

	def spawn_initial_food(self) -> None:
		"""Spawn exactly one regular food at start"""
		new_food = RegularFood(self.config, food_type=FoodType.RED)
		while new_food.position in self.snake.positions:
			new_food.randomize_position(self.config.grid_width, self.config.grid_height)
		self.foods.append(new_food)

	def update_movement_divisor(self, multiplier: float) -> None:
		"""Update divisor: multiplier > 1 slows movement, < 1 speeds it up"""
		self.current_divisor = max(1, int(self.config.movement_divisor * multiplier))
		self.frame_count = 0  # Reset to avoid a jump

	def spawn_food_after_eat(self, eaten_position: tuple[int, int]) -> None:
		"""Replace eaten food with a regular food + optional power-up (if none present)"""
		# Replace with a regular food at the eaten spot
		regular = RegularFood(
			self.config, position=eaten_position, food_type=FoodType.RED
		)
		while regular.position in self.snake.positions:
			regular.randomize_position(self.config.grid_width, self.config.grid_height)
		self.foods = [regular]  # Clear any existing regular food

		# Spawn power-up only if one doesn't exist yet (max 1 power-up)
		has_powerup = any(isinstance(f, PowerUpFood) for f in self.foods)
		if not has_powerup and random.random() < 0.10:
			powerup = PowerUpFood(self.config)
			while (
				powerup.position in self.snake.positions
				or powerup.position == regular.position
			):
				powerup.randomize_position(
					self.config.grid_width, self.config.grid_height
				)
			self.foods.append(powerup)

	def handle_input(self) -> None:
		"""Poll all pending events and queue direction changes (unless game over)"""
		for event in pygame.event.get():
			if event.type == pygame.QUIT:
				pygame.quit()
				sys.exit()
			elif event.type == pygame.KEYDOWN:
				# Always allow restart
				if event.key == pygame.K_r and self.game_over:
					self.restart()
					return
				# Toggle pause with P or Esc (only during gameplay)
				elif (
					event.key == pygame.K_p or event.key == pygame.K_ESCAPE
				) and not self.game_over:
					if not self.paused:
						self._pause_start_ms = now_ms()
					else:
						elapsed_while_paused = now_ms() - self._pause_start_ms
						self._total_paused_offset_ms += elapsed_while_paused
						self._pause_start_ms = None
					self.paused = not self.paused
					return
				elif event.key == pygame.K_q and not self.paused:
					pygame.quit()
					sys.exit()

				if self.game_over:
					continue  # Block movements on game over

				if self.paused:
					continue  # Block movements while paused

				# Direction keys
				if event.key == pygame.K_UP or event.key == pygame.K_w:
					self.input_queue.append(Direction.UP)
				elif event.key == pygame.K_DOWN or event.key == pygame.K_s:
					self.input_queue.append(Direction.DOWN)
				elif event.key == pygame.K_LEFT or event.key == pygame.K_a:
					self.input_queue.append(Direction.LEFT)
				elif event.key == pygame.K_RIGHT or event.key == pygame.K_d:
					self.input_queue.append(Direction.RIGHT)

	def process_movement(self) -> None:
		"""Process ONE queued input and move snake"""
		if self.input_queue:
			new_dir = self.input_queue.popleft()
			self.snake.change_direction(new_dir)

		invincible = self.invincible_until > self._effective_time_ms()
		wall_collision = self.snake.move(self.config.lethal_walls, invincible)
		if wall_collision and not invincible:
			self.game_over = True
		head_pos = self.snake.get_head_position()
		if not invincible and head_pos in self.snake.positions[1:]:
			self.game_over = True

	def update_food_collisions(self) -> None:
		"""Check and handle snake eating food"""
		head_pos = self.snake.get_head_position()
		for food in self.foods[:]:
			if head_pos == food.position:
				food.apply_effect(self)
				self.snake.grow(food.points)

				text = FloatingText.new(
					food=food,
					grid_size=self.config.grid_size,
				)

				if text is not None:
					self.floating_texts.append(text)

				self.foods.remove(food)
				self.spawn_food_after_eat(food.position)

	def update_effects(self) -> None:
		"""Check and expire active effects"""
		now = self._effective_time_ms()
		if self.slow_until and now > self.slow_until:
			self.current_divisor = self.config.movement_divisor
			self.slow_until = 0
		if self.speed_until and now > self.speed_until:
			self.current_divisor = self.config.movement_divisor
			self.speed_until = 0

	def update(self) -> None:
		"""Game logic update - called every frame"""
		self.frame_count += 1

		# Move snake on divisor frames
		if self.frame_count % self.current_divisor == 0 and not self.game_over:
			self.process_movement()

		# Food collision check every frame
		self.update_food_collisions()

		# Effect expiration check every frame
		self.update_effects()

	def update_floating_texts(self, delta_ms: float) -> None:
		"""Update floating text animations"""
		for ft in self.floating_texts[:]:
			ft.update(delta_ms)
			if not ft.is_alive():
				self.floating_texts.remove(ft)

	def draw(self) -> None:
		self.screen.fill(self.config.background_color)

		# Draw snake with dead coloring if applicable
		is_invincible = self.invincible_until > self._effective_time_ms()
		for idx, pos in enumerate(self.snake.positions):
			is_head = idx == 0
			color = self.config.snake_color
			if self.game_over and not is_invincible and not is_head:
				color = self.config.snake_dead_color
			pygame.draw.rect(
				self.screen,
				color,
				pygame.Rect(
					pos[0] * self.config.grid_size,
					pos[1] * self.config.grid_size,
					self.config.grid_size,
					self.config.grid_size,
				),
			)

		# Draw food
		for food in self.foods:
			pygame.draw.rect(
				self.screen,
				food.color,
				pygame.Rect(
					food.position[0] * self.config.grid_size,
					food.position[1] * self.config.grid_size,
					self.config.grid_size,
					self.config.grid_size,
				),
			)

		# Draw active effect progress bars (top-right)
		self._draw_active_effects()

		# Draw floating texts
		for ft in self.floating_texts:
			alpha = ft.get_alpha()
			if alpha > 0:
				text_surface = self.small_font.render(ft.text, True, ft.color)
				text_surface.set_alpha(alpha)
				self.screen.blit(text_surface, (ft.x, ft.y))

		# Draw score
		score_text = self.font.render(
			f"Score: {self.score}", True, self.config.font_color
		)
		self.screen.blit(score_text, (10, 10))

		if self.game_over:
			over_text = self.font.render(
				"Game Over! Press R to restart", True, self.config.font_color
			)
			self.screen.blit(
				over_text,
				(self.config.window_width // 2 - 150, self.config.window_height // 2),
			)

		if self.paused:
			# Dim background overlay
			overlay = pygame.Surface(
				(self.config.window_width, self.config.window_height), pygame.SRCALPHA
			)
			overlay.fill((0, 0, 0, 140))
			self.screen.blit(overlay, (0, 0))

			# "PAUSED" text in center
			paused_text = self.large_font.render("PAUSED", True, self.config.font_color)
			paused_rect = paused_text.get_rect(
				center=(self.config.window_width // 2, self.config.window_height // 3)
			)
			self.screen.blit(paused_text, paused_rect)

			# Fruit effects legend in top-right corner
			menu_x = self.config.window_width - 280
			menu_y = 50
			padding = 6
			item_h = 24

			# Semi-transparent background box for the legend
			entries = self._get_fruit_entries()
			box_height = len(entries) * item_h + padding * 2
			menu_bg = pygame.Surface((260, box_height), pygame.SRCALPHA)
			menu_bg.fill((0, 0, 0, 180))
			self.screen.blit(menu_bg, (menu_x - 5, menu_y - 5))

			for i, entry in enumerate(entries):
				fruit_color = pygame.Color(entry["r"], entry["g"], entry["b"])
				dot_rect = pygame.Rect(menu_x, menu_y + i * item_h + padding, 14, 14)
				pygame.draw.rect(self.screen, fruit_color, dot_rect)
				# Draw a small border so it's visible on light backgrounds
				pygame.draw.rect(
					self.screen, (255, 255, 255), (*dot_rect.topleft, 14, 14), 1
				)

				label = f"{entry['desc']}: {entry['effect']}"
				text_surface = self.small_font.render(label, True, (200, 200, 200))
				self.screen.blit(text_surface, (dot_rect.right + 8, dot_rect.y - 1))

		pygame.display.flip()

	def _get_active_effects(self) -> list[ActiveEffect]:
		"""Return any currently active effect information."""
		now = self._effective_time_ms()
		effects: list[ActiveEffect] = []

		if self.invincible_until and now < self.invincible_until:
			remaining = (self.invincible_until - now) / float(
				self.config.invincibility_duration
			)
			effects.append(
				ActiveEffect(
					name="INVINCIBLE",
					color=(51, 51, 255),
					bar_color=(130, 130, 255),
					progress=max(remaining, 0.0),
				)
			)

		if self.slow_until and now < self.slow_until:
			remaining = (self.slow_until - now) / float(self.config.slow_duration)
			effects.append(
				ActiveEffect(
					name="SLOW",
					color=(221, 221, 221),
					bar_color=(180, 180, 180),
					progress=max(remaining, 0.0),
				)
			)

		if self.speed_until and now < self.speed_until:
			remaining = (self.speed_until - now) / float(self.config.speed_duration)
			effects.append(
				ActiveEffect(
					name="SPEED",
					color=(51, 51, 51),
					bar_color=(130, 130, 130),
					progress=max(remaining, 0.0),
				)
			)

		return effects

	def _effective_time_ms(self) -> float:
		"""
		Return game time with paused duration removed.
		While paused, this stays frozen at the pause-start instant.
		"""
		now = now_ms()
		pending_pause = (
			now - self._pause_start_ms
			if self.paused and self._pause_start_ms is not None
			else 0.0
		)
		return now - (self._total_paused_offset_ms + pending_pause)

	def _draw_active_effects(self) -> None:
		"""Draw effect progress bars at top-right of screen."""
		effects = self._get_active_effects()
		if not effects:
			return

		x_start = self.config.window_width - 260
		bar_height = 8
		text_height = 14
		spacing = 4
		y = 10

		for eff in effects:
			# Effect name label above bar
			text_surface = self.small_font.render(eff.name, True, eff.color)
			self.screen.blit(text_surface, (x_start, y))

			# Bar background (empty portion)
			bg_rect = pygame.Rect(
				x_start,
				y + text_height + spacing,
				220,  # bar width
				bar_height,
			)
			pygame.draw.rect(self.screen, (60, 60, 60), bg_rect)

			# Bar fill (progress portion)
			fill_width = max(int(220 * eff.progress), 1)
			fill_rect = pygame.Rect(
				x_start,
				y + text_height + spacing,
				fill_width,
				bar_height,
			)
			pygame.draw.rect(self.screen, eff.bar_color, fill_rect)

			# Bar border
			pygame.draw.rect(
				self.screen,
				(100, 100, 100),
				(*bg_rect.topleft, bg_rect.width, bg_rect.height),
				1,
			)

			y += text_height + spacing + bar_height + spacing * 2

	def _get_fruit_entries(self) -> list[dict]:
		"""Return fruit type descriptions for the pause-menu legend."""
		return [
			{
				"r": 51,
				"g": 51,
				"b": 255,
				"desc": "Blue (INV)",
				"effect": "Invincibility\u2013no wall/self damage",
			},
			{
				"r": 221,
				"g": 221,
				"b": 221,
				"desc": "White (SLOW)",
				"effect": "Slows the snake down",
			},
			{
				"r": 51,
				"g": 51,
				"b": 51,
				"desc": "Gray (SPD)",
				"effect": "Speeds the snake up",
			},
		]

	def restart(self) -> None:
		self.snake = Snake(
			self.config.grid_width // 2, self.config.grid_height // 2, self.config
		)
		self.foods.clear()
		self.score = 0
		self.game_over = False
		self.paused = False
		self._pause_start_ms = None
		self._total_paused_offset_ms = 0.0
		self.invincible_until = 0
		self.slow_until = 0
		self.speed_until = 0
		self.current_divisor = self.config.movement_divisor
		self.frame_count = 0
		self.input_queue.clear()
		self.floating_texts.clear()
		self.spawn_initial_food()

	def run(self) -> None:
		last_time = time.time()
		while True:
			now = time.time()
			delta_ms = (now - last_time) * 1000
			last_time = now

			self.handle_input()
			if not self.paused and not self.game_over:
				self.update()
				self.update_floating_texts(delta_ms)
			elif not self.game_over:
				# Still update floating texts while paused so they don't just freeze mid-animation
				self.update_floating_texts(delta_ms)
			self.draw()
			self.clock.tick(self.config.fps)  # 60 FPS render


if __name__ == "__main__":
	parser = argparse.ArgumentParser(
		description="Snake Game with configurable settings"
	)
	parser.add_argument("--width", type=int, default=800, help="Window width")
	parser.add_argument("--height", type=int, default=600, help="Window height")
	parser.add_argument("--grid", type=int, default=20, help="Grid size in pixels")
	parser.add_argument("--fps", type=int, default=60, help="Rendering FPS")
	parser.add_argument(
		"--divisor",
		type=int,
		default=6,
		help="Movement divisor: snake moves every N frames (lower = faster)",
	)
	parser.add_argument("--length", type=int, default=3, help="Initial snake length")
	parser.add_argument(
		"--lethal-walls", action="store_true", help="Enable fatal wall collisions"
	)
	args = parser.parse_args()
	cfg = GameConfig(
		window_width=args.width,
		window_height=args.height,
		grid_size=args.grid,
		fps=args.fps,
		movement_divisor=args.divisor,
		initial_snake_length=args.length,
		lethal_walls=args.lethal_walls,
	)
	game = Game(cfg)
	game.run()
