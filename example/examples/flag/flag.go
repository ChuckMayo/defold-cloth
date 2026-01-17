components {
  id: "script"
  component: "/example/examples/flag/flag.script"
}
embedded_components {
  id: "pole"
  type: "sprite"
  data: "default_animation: \"banner\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/example/assets/examples.atlas\"\n"
  "}\n"
  ""
  position {
    x: -200.0
    y: -201.0
    z: -0.1
  }
  scale {
    x: 0.03
    y: 1.5
  }
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"flag\"\n"
  "material: \"/cloth/materials/cloth.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/example/assets/examples.atlas\"\n"
  "}\n"
  ""
}
