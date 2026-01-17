components {
  id: "script"
  component: "/example/examples/cape_mesh/cape_mesh.script"
}
embedded_components {
  id: "mesh"
  type: "mesh"
  data: "material: \"/cloth/materials/cloth_mesh.material\"\n"
  "vertices: \"/cloth/meshes/placeholder.buffer\"\n"
  "textures: \"/example/assets/cape.png\"\n"
  "primitive_type: PRIMITIVE_TRIANGLES\n"
  "position_stream: \"position\"\n"
  "normal_stream: \"normal\"\n"
  ""
}
