extends Node3D

var normal_color: Color = Color.RED
var normal_length: float = 1.0  # Length of normal lines

var m_material: BaseMaterial3D = StandardMaterial3D.new()
var main_mesh: MeshInstance3D = MeshInstance3D.new()
var debug_mesh: ImmediateMesh = ImmediateMesh.new()   # New mesh for drawing normals

var vector1: Vector3 = Vector3.ZERO
var vector2: Vector3 = Vector3.UP

func _ready():
	main_mesh.set_notify_local_transform(false)
	m_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m_material.albedo_color = normal_color
	update_debug_mesh()
	add_child(main_mesh)

func _process(delta: float) -> void:
	var parent_transform = get_parent().transform.inverse()
	main_mesh.transform = parent_transform

func draw_vector(from: Vector3,to: Vector3):
	vector1 = from
	vector2 = to
	update_debug_mesh()

func update_debug_mesh():
	debug_mesh.clear_surfaces()
	debug_mesh.surface_begin(Mesh.PRIMITIVE_LINES, m_material)

	debug_mesh.surface_add_vertex(vector1)
	debug_mesh.surface_add_vertex(vector2)

	debug_mesh.surface_end()
	main_mesh.mesh = debug_mesh
