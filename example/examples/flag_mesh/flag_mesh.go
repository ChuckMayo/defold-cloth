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
    x: -157.0
    y: 127.0
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
    x: -288.0
    y: -69.0
    z: -0.1
  }
  scale {
    x: 0.03
    y: 1.5
  }
}
embedded_components {
  id: "debug_wave_xy"
  type: "mesh"
  data: "material: \"/example/examples/flag_mesh/materials/debug_wave_xy.material\"\n"
  "vertices: \"/cloth/meshes/placeholder.buffer\"\n"
  "position_stream: \"position\"\n"
  "normal_stream: \"normal\"\n"
  ""
  position {
    x: 100.0
    y: 150.0
    z: 0.1
  }
}
embedded_components {
  id: "debug_wave_z"
  type: "mesh"
  data: "material: \"/example/examples/flag_mesh/materials/debug_wave_z.material\"\n"
  "vertices: \"/cloth/meshes/placeholder.buffer\"\n"
  "position_stream: \"position\"\n"
  "normal_stream: \"normal\"\n"
  ""
  position {
    x: 200.0
    y: 150.0
    z: 0.1
  }
}
embedded_components {
  id: "debug_wobble"
  type: "mesh"
  data: "material: \"/example/examples/flag_mesh/materials/debug_wobble.material\"\n"
  "vertices: \"/cloth/meshes/placeholder.buffer\"\n"
  "position_stream: \"position\"\n"
  "normal_stream: \"normal\"\n"
  ""
  position {
    x: 300.0
    y: 150.0
    z: 0.1
  }
}
embedded_components {
  id: "debug_noise"
  type: "mesh"
  data: "material: \"/example/examples/flag_mesh/materials/debug_noise.material\"\n"
  "vertices: \"/cloth/meshes/placeholder.buffer\"\n"
  "position_stream: \"position\"\n"
  "normal_stream: \"normal\"\n"
  ""
  position {
    x: 100.0
    y: 60.0
    z: 0.1
  }
}
embedded_components {
  id: "debug_gust"
  type: "mesh"
  data: "material: \"/example/examples/flag_mesh/materials/debug_gust.material\"\n"
  "vertices: \"/cloth/meshes/placeholder.buffer\"\n"
  "position_stream: \"position\"\n"
  "normal_stream: \"normal\"\n"
  ""
  position {
    x: 200.0
    y: 60.0
    z: 0.1
  }
}
embedded_components {
  id: "debug_influence"
  type: "mesh"
  data: "material: \"/example/examples/flag_mesh/materials/debug_influence.material\"\n"
  "vertices: \"/cloth/meshes/placeholder.buffer\"\n"
  "position_stream: \"position\"\n"
  "normal_stream: \"normal\"\n"
  ""
  position {
    x: 300.0
    y: 60.0
    z: 0.1
  }
}
