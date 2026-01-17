--- MeshGenerator - Creates grid mesh buffers for cloth animation
--- Generates runtime buffers with vertices in triangle order for Defold mesh components.

local MeshGenerator = {}

--- Creates a grid mesh buffer for cloth animation
--- @param cols number Number of columns in the grid (vertices horizontally)
--- @param rows number Number of rows in the grid (vertices vertically)
--- @param width number Total width of the mesh in pixels
--- @param height number Total height of the mesh in pixels
--- @return buffer The created buffer with position and texcoord0 streams
function MeshGenerator.create_grid(cols, rows, width, height)
    -- Calculate number of quads and triangles
    local num_quads = (cols - 1) * (rows - 1)
    local num_triangles = num_quads * 2
    local num_vertices = num_triangles * 3

    -- Create buffer with position (3 floats), texcoord0 (2 floats), and normal (3 floats)
    local buf = buffer.create(num_vertices, {
        { name = hash("position"), type = buffer.VALUE_TYPE_FLOAT32, count = 3 },
        { name = hash("texcoord0"), type = buffer.VALUE_TYPE_FLOAT32, count = 2 },
        { name = hash("normal"), type = buffer.VALUE_TYPE_FLOAT32, count = 3 }
    })

    local positions = buffer.get_stream(buf, hash("position"))
    local texcoords = buffer.get_stream(buf, hash("texcoord0"))

    -- Half dimensions for centering
    local half_w = width / 2
    local half_h = height / 2

    -- Cell size
    local cell_w = width / (cols - 1)
    local cell_h = height / (rows - 1)

    local vertex_index = 1

    -- Generate triangles for each quad
    for row = 0, rows - 2 do
        for col = 0, cols - 2 do
            -- Four corners of this quad
            -- Top-left (TL), Top-right (TR), Bottom-left (BL), Bottom-right (BR)
            local x0 = col * cell_w - half_w       -- left
            local x1 = (col + 1) * cell_w - half_w -- right
            local y0 = half_h - row * cell_h       -- top (positive Y)
            local y1 = half_h - (row + 1) * cell_h -- bottom (less positive Y)

            -- UV coordinates (0-1 range)
            local u0 = col / (cols - 1)
            local u1 = (col + 1) / (cols - 1)
            local v0 = row / (rows - 1)
            local v1 = (row + 1) / (rows - 1)

            -- Triangle 1: TL, TR, BL
            -- TL
            positions[vertex_index] = x0
            positions[vertex_index + 1] = y0
            positions[vertex_index + 2] = 0
            texcoords[(vertex_index - 1) * 2 / 3 + 1] = u0
            texcoords[(vertex_index - 1) * 2 / 3 + 2] = v0

            -- Wait, buffer streams are indexed per-component, not per-vertex
            -- Let me reconsider the indexing...
        end
    end

    -- Actually, buffer streams use per-component indexing
    -- For position (count=3): index 1,2,3 = vertex 0's x,y,z
    -- For texcoord0 (count=2): index 1,2 = vertex 0's u,v

    -- Let me rewrite with correct indexing
    return MeshGenerator._fill_grid_buffer(buf, cols, rows, width, height)
end

function MeshGenerator._fill_grid_buffer(buf, cols, rows, width, height)
    local positions = buffer.get_stream(buf, hash("position"))
    local texcoords = buffer.get_stream(buf, hash("texcoord0"))
    local normals = buffer.get_stream(buf, hash("normal"))

    local half_w = width / 2
    local half_h = height / 2
    local cell_w = width / (cols - 1)
    local cell_h = height / (rows - 1)

    local pos_idx = 1  -- 1-based index for position stream
    local tex_idx = 1  -- 1-based index for texcoord stream
    local nrm_idx = 1  -- 1-based index for normal stream

    local function add_vertex(x, y, u, v)
        positions[pos_idx] = x
        positions[pos_idx + 1] = y
        positions[pos_idx + 2] = 0
        pos_idx = pos_idx + 3

        texcoords[tex_idx] = u
        texcoords[tex_idx + 1] = v
        tex_idx = tex_idx + 2

        -- All normals point toward camera (+Z)
        normals[nrm_idx] = 0
        normals[nrm_idx + 1] = 0
        normals[nrm_idx + 2] = 1
        nrm_idx = nrm_idx + 3
    end

    -- Generate triangles for each quad
    for row = 0, rows - 2 do
        for col = 0, cols - 2 do
            -- Quad corners
            local x0 = col * cell_w - half_w
            local x1 = (col + 1) * cell_w - half_w
            local y0 = half_h - row * cell_h
            local y1 = half_h - (row + 1) * cell_h

            -- UV coordinates (V is flipped: 1 at top, 0 at bottom for OpenGL/Defold)
            local u0 = col / (cols - 1)
            local u1 = (col + 1) / (cols - 1)
            local v0 = 1.0 - row / (rows - 1)          -- Flip V: row 0 = v=1 (top of texture)
            local v1 = 1.0 - (row + 1) / (rows - 1)    -- row N = v=0 (bottom of texture)

            -- Triangle 1: TL, TR, BL (counter-clockwise for front-facing)
            add_vertex(x0, y0, u0, v0)  -- TL
            add_vertex(x1, y0, u1, v0)  -- TR
            add_vertex(x0, y1, u0, v1)  -- BL

            -- Triangle 2: BL, TR, BR
            add_vertex(x0, y1, u0, v1)  -- BL
            add_vertex(x1, y0, u1, v0)  -- TR
            add_vertex(x1, y1, u1, v1)  -- BR
        end
    end

    return buf
end

-- Counter for unique resource paths
local resource_counter = 0

--- Creates a resource buffer and sets it on a mesh component
--- @param mesh_url url URL of the mesh component
--- @param cols number Grid columns
--- @param rows number Grid rows
--- @param width number Mesh width in pixels
--- @param height number Mesh height in pixels
--- @return buffer The created buffer
function MeshGenerator.setup_mesh(mesh_url, cols, rows, width, height)
    local buf = MeshGenerator.create_grid(cols, rows, width, height)
    -- Use unique path for each mesh instance
    resource_counter = resource_counter + 1
    local resource_path = "/cloth_mesh_buffer_" .. resource_counter .. ".bufferc"
    local res = resource.create_buffer(resource_path, { buffer = buf })
    go.set(mesh_url, "vertices", res)
    return buf
end

return MeshGenerator
