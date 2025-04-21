#Attach script to a MeshInstance3D to show normal vectors of faces

extends MeshInstance3D

@export var normal_color: Color = Color.RED
@export var normal_length: float = 1.0  # Length of normal lines

var m_material: BaseMaterial3D = StandardMaterial3D.new()
var main_mesh: MeshInstance3D = MeshInstance3D.new()
var debug_mesh: ImmediateMesh = ImmediateMesh.new()   # New mesh for drawing normals

func _ready():
	m_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m_material.albedo_color = normal_color
	update_debug_mesh()
	add_child(main_mesh)

func _process(delta):
	update_debug_mesh()

func update_debug_mesh():
	debug_mesh.clear_surfaces()
	debug_mesh.surface_begin(Mesh.PRIMITIVE_LINES, m_material)

	for surface_index in mesh.get_surface_count():
		var arrays = mesh.surface_get_arrays(surface_index)
		if arrays.size() <= Mesh.ARRAY_VERTEX:
			continue

		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]

		if indices.size() == 0:
			continue  # Skip if no index array is present

		for i in range(0, indices.size(), 3):
			# Retrieve vertices of the triangle
			var v0 = vertices[indices[i]]
			var v1 = vertices[indices[i + 1]]
			var v2 = vertices[indices[i + 2]]

			var center = (v0 + v1 + v2) / 3.0

			# Calculate the normal for the triangle (face normal)
			var normal = -((v1 - v0).cross(v2 - v0))  # This creates the normal

			var end_point = center + normal * normal_length

			# Add line to the ImmediateMesh
			debug_mesh.surface_add_vertex(center)
			debug_mesh.surface_add_vertex(end_point)

	debug_mesh.surface_end()
	main_mesh.mesh = debug_mesh
