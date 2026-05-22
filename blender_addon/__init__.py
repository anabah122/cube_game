bl_info = {
    "name": "chunk_export",
    "version": (1, 0),
    "blender": (3, 6, 0),
    "category": "Import-Export",
}

import bpy
import os
import re
import math
from bpy.props import StringProperty
from bpy_extras.io_utils import ExportHelper


# парсим исходные "chunk_-1_-6" -> (-1, -6)
def parse_chunk_name(name):
    m = re.fullmatch(r'chunk_(-?\d+)_(-?\d+)', name)
    if m:
        return int(m.group(1)), int(m.group(2))
    return None

# парсим результирующие "opt_chunk_0_1" -> (0, 1)
def parse_opt_chunk_name(name):
    m = re.fullmatch(r'opt_chunk_(-?\d+)_(-?\d+)', name)
    if m:
        return int(m.group(1)), int(m.group(2))
    return None


def deselect_all():
    for obj in bpy.context.scene.objects:
        obj.select_set(False)


def do_optimize():
    source_chunks = {}
    for obj in list(bpy.context.scene.objects):
        if obj.type != 'MESH':
            continue
        coords = parse_chunk_name(obj.name)
        if coords is None:
            continue
        cx, cz = coords
        my_x = math.floor(cx / 10)
        my_z = math.floor(cz / 10)
        source_chunks.setdefault((my_x, my_z), []).append(obj)

    deselect_all()

    for (my_x, my_z), objs in source_chunks.items():
        target_name = f"opt_chunk_{my_x}_{my_z}"

        existing = bpy.data.objects.get(target_name)
        if existing:
            bpy.data.objects.remove(existing, do_unlink=True)

        for obj in objs:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objs[0]

        bpy.ops.object.join()
        joined = bpy.context.active_object
        joined.name = target_name


        verts_world = [joined.matrix_world @ v.co for v in joined.data.vertices]
        min_x = min(v.x for v in verts_world)
        min_y = min(v.y for v in verts_world)

        bpy.context.scene.cursor.location = (min_x, min_y, 0.0)
        bpy.ops.object.origin_set(type='ORIGIN_CURSOR')

        deselect_all()

    # remove doubles
    for obj in bpy.context.scene.objects:
        if obj.type != 'MESH' or parse_opt_chunk_name(obj.name) is None:
            continue
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.mesh.remove_doubles()
        bpy.ops.object.mode_set(mode='OBJECT')
        obj.select_set(False)


def do_export(directory):
    do_optimize()

    bpy.ops.object.select_all(action='DESELECT')

    for obj in bpy.context.scene.objects:
        if obj.type != 'MESH' or parse_opt_chunk_name(obj.name) is None:
            continue

        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj

        filepath = os.path.join(directory, obj.name + ".obj")
        bpy.ops.export_scene.obj(
            filepath=filepath,
            use_selection=True,
            use_materials=True,
            use_normals=True,
            use_uvs=True,
            use_triangles=True,
            use_mesh_modifiers=True,
        )

        obj.select_set(False)


# ── Operators ────────────────────────────────────────────────────────────────

class CHUNK_OT_optimize(bpy.types.Operator):
    bl_idname = "chunk.optimize"
    bl_label = "Optimize"
    bl_description = "Merge source chunks into 10x10 my-chunks and remove doubles"

    def execute(self, context):
        do_optimize()
        self.report({'INFO'}, "Optimize done")
        return {'FINISHED'}


class CHUNK_OT_export(bpy.types.Operator, ExportHelper):
    bl_idname = "chunk.export"
    bl_label = "Export"
    bl_description = "Optimize and export each chunk as a separate glTF file"

    filename_ext = ""
    filter_glob: StringProperty(default="", options={'HIDDEN'})
    # ExportHelper ждёт filepath; мы используем его как папку
    filepath: StringProperty(subtype='DIR_PATH')

    def execute(self, context):
        directory = os.path.dirname(self.filepath) if os.path.isfile(self.filepath) else self.filepath
        directory = bpy.path.abspath(directory)
        os.makedirs(directory, exist_ok=True)
        do_export(directory)
        self.report({'INFO'}, f"Exported to {directory}")
        return {'FINISHED'}

    def invoke(self, context, event):
        self.filepath = ""
        context.window_manager.fileselect_add(self)
        return {'RUNNING_MODAL'}


# ── Panel ────────────────────────────────────────────────────────────────────

class CHUNK_PT_panel(bpy.types.Panel):
    bl_label = "Chunk Tools"
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'UI'
    bl_category = "Chunks"

    def draw(self, context):
        layout = self.layout
        layout.operator("chunk.optimize", icon='MESH_DATA')
        layout.operator("chunk.export", icon='EXPORT')


# ── Register ─────────────────────────────────────────────────────────────────

classes = (CHUNK_OT_optimize, CHUNK_OT_export, CHUNK_PT_panel)

def register():
    for c in classes:
        bpy.utils.register_class(c)

def unregister():
    for c in classes:
        bpy.utils.unregister_class(c)

if __name__ == "__main__":
    register()
