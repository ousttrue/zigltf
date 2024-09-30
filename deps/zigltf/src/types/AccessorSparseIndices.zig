pub const AccessorSparseIndices = @This();

bufferView: u32,
byteOffset: u32 = 0,

// 5121(u8) / 5123(u16) / 5125(u32)
componentType: u32,
