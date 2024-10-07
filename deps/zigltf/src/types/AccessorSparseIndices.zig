pub const ComponentType = enum(u32) {
    u8 = 5121,
    u16 = 5123,
    u32 = 5125,
};
pub const AccessorSparseIndices = @This();

bufferView: u32,
byteOffset: u32 = 0,
componentType: ComponentType,
