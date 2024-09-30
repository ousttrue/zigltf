const AccessorSparseIndices = @import("AccessorSparseIndices.zig");
const AccessorSparseValues = @import("AccessorSparseValues.zig");
pub const AccessorSpars = @This();

count: u32,
indices: AccessorSparseIndices,
values: AccessorSparseValues,
