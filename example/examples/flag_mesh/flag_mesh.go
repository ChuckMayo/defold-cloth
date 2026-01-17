components {
  id: "script"
  component: "/example/examples/flag_mesh/flag_mesh.script"
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
  position {
    x: 63.0
    y: 132.0
  }
}
embedded_components {
  id: "pole"
  type: "sprite"
  data: "default_animation: \"banner\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "size {\n"
  "  x: 256.0\n"
  "  y: 384.0\n"
  "}\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/example/assets/examples.atlas\"\n"
  "}\n"
  ""
  position {
    x: -137.0
    y: -69.0
    z: -0.1
  }
  scale {
    x: 0.03
    y: 1.5
  }
}
