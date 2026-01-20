components {
  id: "script"
  component: "/example/examples/stress_test/stress_flag.script"
}
embedded_components {
  id: "mesh"
  type: "mesh"
  data: "material: \"/cloth/materials/cloth_mesh.material\"\n"
  "vertices: \"/cloth/meshes/placeholder.buffer\"\n"
  "textures: \"/example/assets/flag.png\"\n"
  "position_stream: \"position\"\n"
  "normal_stream: \"normal\"\n"
  ""
}
