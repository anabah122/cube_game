return {
    PROJECT_ROOT = 'C:/LOVE/cubach',
    CONVERTER_ROOT = 'C:/LOVE/cubach/terrain_converter',

    SRC_OBJ    = 'input/minecraft.obj',           -- relative to CONVERTER_ROOT
    OUT_DIR    = 'chunks',                        -- relative to CONVERTER_ROOT
    ATLAS_MAP  = 'pack/atlas_map.json',           -- relative to PROJECT_ROOT

    CHUNK_GROUP= 10,
    WORKERS    = 8,
    LOD_CELLS  = { 4 },
}
