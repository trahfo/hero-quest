class_name HeroQuestCameraSmoothing
extends RefCounted

## Frame-rate independent exponential damping with a hard snap epsilon.
## A plain `lerp(a, b, k * delta)` never reaches its target; the camera keeps creeping
## sub-pixel for 1-2 s after the hero stops, which makes coplanar surfaces and
## occlusion rays shimmer. These helpers converge exactly and then stop moving.

const POS_EPSILON: float = 0.004
const SCALAR_EPSILON: float = 0.004
const ANGLE_EPSILON: float = 0.0005

static func damp_vec3(current: Vector3, target: Vector3, rate: float, delta: float) -> Vector3:
	if current.distance_squared_to(target) <= POS_EPSILON * POS_EPSILON:
		return target
	return current.lerp(target, 1.0 - exp(-rate * delta))

static func damp_float(current: float, target: float, rate: float, delta: float) -> float:
	if absf(target - current) <= SCALAR_EPSILON:
		return target
	return lerpf(current, target, 1.0 - exp(-rate * delta))

static func damp_angle(current: float, target: float, rate: float, delta: float) -> float:
	if absf(angle_difference(current, target)) <= ANGLE_EPSILON:
		return target
	return lerp_angle(current, target, 1.0 - exp(-rate * delta))
