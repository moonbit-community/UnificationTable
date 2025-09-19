# disjoint-set

## Introduction
The disjoint-set, also known as union-find, is a data structure that efficiently supports set union and find operations. It is widely used in various fields such as graph algorithms, type inference, and equivalence class management, and plays a key role in compiler implementation (e.g., for type unification and region analysis).

## Features

- Implements the classic union-find algorithm with path compression and union by rank.
- Supports set initialization, union, and finding the representative element (find).
- Supports dynamic elements (no need to pre-allocate the total number of elements).
- Optionally supports persistent (versioned) structures or undo operations.
- Optionally implements a "value merging" feature (e.g., for unifying types).
- Designed with a clean API for easy use in scenarios like compiler implementation, graph algorithms, and region analysis.

## Example
### UnificationTable

> **Note:** Snapshot operations should follow a stack-like (LIFO) order.  
> A root snapshot is required for snapshot operations.  
>  Avoid using the `new_index` method; use `table.index` to obtain the index instead.

```moonbit
///|
test "UnificationTable::union_test" {
  let table = UnificationTable::new(capacity=5)
  for i in 0..<5 {
    table.push(i)
  }
  let index1 = table.index(1)
  let index2 = table.index(2)
  let index3 = table.index(3)
  assert_false!(table.unioned(index1, index2))
  let _ = table.unite(index1, index2, 8)
  assert_true!(table.unioned(index1, index2))
  assert_false!(table.unioned(index1, index3))
  assert_true!(table.unioned(index2, index1))
  assert_false!(table.unioned(index2, index3))
}
```

### Snapshot

```moonbit
///|
test "UnificationTable::snapshot_unite_test" {
  let table = UnificationTable::new(capacity=5)
  let _ = table.start_snapshot()
  for i in 0..<5 {
    table.push(i)
  }
  let s1 = table.start_snapshot()
  let index1 = table.index(1)
  let index2 = table.index(2)
  let index3 = table.index(3)
  assert_false!(table.unioned(index1, index2))
  let _ = table.unite(index1, index2, 8)
  assert_true!(table.unioned(index1, index2))
  assert_false!(table.unioned(index1, index3))
  assert_false!(table.unioned(index2, index3))
  table.rollback_to(s1)
  assert_false!(table.unioned(index1, index2))
  assert_false!(table.unioned(index1, index3))
  assert_false!(table.unioned(index2, index1))
}
```

# Reference
[ena](https://github.com/rust-lang/ena)
