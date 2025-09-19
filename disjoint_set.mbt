/// Disjoint-set implementation. The main type is `UnificationTable`.
/// 
/// It features an abstraction over "keys" and "values," enabling it
/// to handle not only classic set union and find operations but also
/// more complex unification needs, such as carrying information in
/// equivalence classes during type inference.
/// 
/// Each equivalence set's representative element (root) can be associated
/// with a "value" to carry extra information for that set. For instance, 
/// in constraint solving or typeunification, this value can store 
/// known type information or constraint results, and these values are merged  
/// when two keys are unified. If you only need the functionality of a "pure" 
/// union-find data structure (grouping elements without extra information),
///  you can set the `Value` to `()`, indicating that no value is carried.

///|
pub struct VarIndex {
  index : Int
}

///|
pub struct VarValue[T] {
  mut value : T
  mut rank : Int
  mut parent : VarIndex
}

///|
pub struct UnificationTable[T] {
  values : @snapshot_array.SnapshotArray[VarValue[T]]
}

///|
pub struct Snapshot {
  snapshot : @snapshot_array.Snapshot
}

///|
/// Creates a new variable value with the specified value, rank, and parent index.
///
/// Parameters:
///
/// * `value`: The initial value of type `T` to store in the variable.
/// * `rank`: The initial rank of the variable in the union-find tree.
/// * `parent`: The index of the parent variable in the union-find structure.
///
/// Returns a new `VarValue[T]` instance containing the specified value, rank,
/// and parent index.
///
/// Example:
///
/// ```moonbit
/// let index = VarIndex::new(0)
/// let var_value = VarValue::new(42, 0, index)
/// inspect(var_value.value, content="42")
/// inspect(var_value.rank, content="0")
/// inspect(var_value.parent.index, content="0")
/// ```
pub fn[T] VarValue::new(
  value : T,
  rank : Int,
  parent : VarIndex,
) -> VarValue[T] {
  { value, rank, parent }
}

///|
/// Redirects the parent pointer of a variable value to a new variable index.
///
/// Parameters:
///
/// * `to`: The new parent index to point to.
///
/// Example:
///
/// ```moonbit
/// let old_parent = VarIndex::new(0)
/// let new_parent = VarIndex::new(1)
/// let var_value = VarValue::new(42, 0, old_parent)
/// let var_value = var_value.redirect(new_parent)
/// inspect(var_value.parent.index, content="1")
/// ```
pub fn[T] VarValue::redirect(self : VarValue[T], to : VarIndex) -> VarValue[T] {
  VarValue::new(self.value, self.rank, to)
}

///|
/// Updates the root node of a union-find tree with new rank and value.
///
/// Parameters:
///
/// * `rank`: The new rank value to be assigned.
/// * `value`: The new value of type `T` to be stored.
///
/// Example:
///
/// ```moonbit
/// let index = VarIndex::new(0)
/// let var_value = VarValue::new(42, 0, index)
/// let var_value = var_value.root(1, 100)
/// inspect(var_value.value, content="100")
/// inspect(var_value.rank, content="1")
/// ```
pub fn[T] VarValue::root(
  self : VarValue[T],
  rank : Int,
  value : T,
) -> VarValue[T] {
  VarValue::new(value, rank, self.parent)
}

///|
/// Updates the root node of a union-find tree with new value.
/// 
/// Parameters:
/// * `value`: The new value of type `T` to be stored.
/// 
/// Example:
/// ```moonbit
/// let index = VarIndex::new(0)
/// let var_value = VarValue::new(42, 0, index)
/// var_value.modify(100)
/// inspect(var_value.value, content="100")
/// ```
pub fn[T] modify(self : VarValue[T], value : T) -> Unit {
  self.value = value
}

///|
/// Creates a new `VarIndex` with the specified index.
pub fn VarIndex::new(index : Int) -> VarIndex {
  { index, }
}

///|
/// Creates a new `Snapshot` from a `snapshot_array.Snapshot`.
pub fn new_snapshot(snapshot : @snapshot_array.Snapshot) -> Snapshot {
  { snapshot, }
}

///|
pub impl[T : Eq] Eq for VarValue[T] with equal(self, other) {
  return self.value == other.value && self.parent == other.parent
}

///|
pub impl Eq for VarIndex with equal(self, other) {
  return self.index == other.index
}

///|
/// Creates a new unification table with a specified initial capacity.
///
/// Parameters:
///
/// * `capacity` : The initial capacity of the table, indicating how many
/// variables can be stored initially.
///
/// Example:
///
/// ```moonbit
/// let table : UnificationTable[Int] = UnificationTable::new(capacity=10)
/// inspect(table.values.length(), content="0")
/// ```
pub fn[T] UnificationTable::new(capacity~ : Int) -> UnificationTable[T] {
  { values: @snapshot_array.SnapshotArray::new(capacity~) }
}

///|
/// Adds a new variable to the unification table.
/// The new variable is initially assigned a rank of 0 and is set as its own parent
///
/// Parameters:
///
/// * `value` : The value to be associated with the new variable.
///
/// Example:
///
/// ```moonbit
/// let table : UnificationTable[Int] = UnificationTable::new(capacity=5)
/// table.push(1)
/// assert_true(table.values.length() == 1)
/// ```
pub fn[T] UnificationTable::push(self : UnificationTable[T], value : T) -> Unit {
  self.values.push({
    value,
    rank: 0,
    parent: VarIndex::new(self.values.length()),
  })
}

///|
/// Adds a variable value directly to the unification table. Unlike push which
/// creates a new variable value from a given value, this function allows adding
/// a pre-constructed variable value.
///
/// Parameters:
///
/// * `var_value` : A pre-constructed variable value to be added to the table.
///
/// Example:
///
/// ```moonbit
/// let table : UnificationTable[Int] = UnificationTable::new(capacity=5)
/// let var_value = VarValue::new(42, 0, VarIndex::new(0))
/// table.push_var(var_value)
/// inspect(table.values.length(), content="1")
/// ```
pub fn[T] UnificationTable::push_var(
  self : UnificationTable[T],
  value : VarValue[T],
) -> Unit {
  self.values.push(value)
}

///|
/// Retrieves a variable value at the specified index from the unification table.
///
/// Parameters:
///
/// * `index`: The integer index of the desired variable value in the table.
///
/// Returns an optional `VarValue[T]`. Returns `Some(value)` if the index is
/// within bounds, or `None` if the index is out of bounds.
///
/// Example:
///
/// ```moonbit
/// let table : UnificationTable[Int] = UnificationTable::new(capacity=5)
/// table.push(42)
/// inspect(
///   table.get(0),
///   content="Some(VarValue { value: 42, rank: 0, parent: VarIndex { index: 0 } })",
/// )
/// inspect(table.get(1), content="None")
/// ```
pub fn[T] UnificationTable::get(
  self : UnificationTable[T],
  index : Int,
) -> VarValue[T]? {
  self.values.get(index)
}

///|
/// Retrieves the parent index of a variable at the specified position in the
/// unification table. Aborts if the index is out of bounds.
///
/// Parameters:
///
/// * `self` : The unification table containing the variables.
/// * `index` : The position of the variable in the table.
///
/// Returns the parent index (`VarIndex`) of the variable at the specified
/// position.
///
/// Example:
///
/// ```moonbit
/// let table : UnificationTable[Int] = UnificationTable::new(capacity=5)
/// table.push(42)
/// inspect(table.index(0).index, content="0")
/// ```
pub fn[T] UnificationTable::index(
  self : UnificationTable[T],
  index : Int,
) -> VarIndex {
  if index < 0 || index >= self.values.length() {
    abort("Index out of bounds")
  }
  let value = self.values.get(index).unwrap()
  value.parent
}

///|
/// Retrieves the variable value from the unification table at the given VarIndex.
///
/// Parameters:
///
/// * `index` : A variable index indicating the position to look up.
///
/// Example:
///
/// ```moonbit
/// let table : UnificationTable[Int] = UnificationTable::new(capacity=5)
/// table.push(42)
/// let index = VarIndex::new(0)
/// inspect(
///   table.value(index),
///   content="VarValue { value: 42, rank: 0, parent: VarIndex { index: 0 } }",
/// )
/// ```
pub fn[T] UnificationTable::value(
  self : UnificationTable[T],
  index : VarIndex,
) -> VarValue[T] {
  self.get(index.index).unwrap()
}

///|
/// Resets all variables in the unification table to their initial states. After
/// reset, each variable becomes its own representative (parent points to itself)
/// with a rank of 0.
///
/// Example:
///
/// ```moonbit
/// let table : UnificationTable[Int] = UnificationTable::new(capacity=2)
/// table.push(1)
/// table.push(2)
/// let _ = table.unite(VarIndex::new(0), VarIndex::new(1), 42)
/// table.reset()
/// inspect(
///   table.unioned(VarIndex::new(0), VarIndex::new(1)),
///   content="false",
/// )
/// ```
pub fn[T] UnificationTable::reset(self : UnificationTable[T]) -> Unit {
  for index, value in self.values.values {
    value.rank = 0
    value.parent = VarIndex::new(index)
  }
  self.values.commit_all()
}

///|
/// Sets the variable value at the specified index in the unification table.
///
/// Parameters:
///
/// * `index` : A variable index indicating the position where the value should
/// be set.
/// * `value` : The new variable value to be stored at the specified position.
///
/// Example:
///
/// ```moonbit
/// let table : UnificationTable[Int] = UnificationTable::new(capacity=5)
/// table.push(42)
/// let new_value = VarValue::new(100, 0, VarIndex::new(0))
/// table.set(VarIndex::new(0), new_value)
/// inspect(
///   table.get(0),
///   content="Some(VarValue { value: 100, rank: 0, parent: VarIndex { index: 0 } })",
/// )
/// ```
pub fn[T] UnificationTable::set(
  self : UnificationTable[T],
  index : VarIndex,
  value : VarValue[T],
) -> Unit {
  self.values.set(index.index, value)
}

///|
/// Updates a variable value in the unification table by applying a
/// transformation function.
///
/// Parameters:
/// * `var_index` : The index of the variable value to be updated.
/// * `func` : A function that takes a variable value and performs the desired modifications on it.
///  The modifications are applied to the variable value.
///
/// Example:
///
/// ```moonbit
/// let table : UnificationTable[Int] = UnificationTable::new(capacity=5)
/// table.push(42)
/// table.update(VarIndex::new(0), fn(val) { val.modify(100); val })
/// inspect(
///   table.get(0),
///   content="Some(VarValue { value: 100, rank: 0, parent: VarIndex { index: 0 } })",
/// )
/// ```
pub fn[T] update(
  self : UnificationTable[T],
  index : VarIndex,
  func : (VarValue[T]) -> VarValue[T],
) -> Unit {
  self.set(index, func(self.value(index)))
}

///|
/// Updates the root node in a union-find data structure by redirecting an old
/// root to a new root and updating the rank and value of the new root.
///
/// Parameters:
///
/// * `self` : The unification table containing the variable values.
/// * `new_rank` : The new rank value to be assigned to the root node.
/// * `old_index` : The index of the old root node that will be redirected.
/// * `new_index` : The index of the new root node.
/// * `new_value` : The value to be stored in the new root node.
///
/// Example:
///
/// ```moonbit
/// let table : UnificationTable[Int] = UnificationTable::new(capacity=2)
/// table.push(1)
/// table.push(2)
/// table.redirect_root(1, VarIndex::new(0), VarIndex::new(1), 42)
/// inspect(table.find(VarIndex::new(0)).index, content="1")
/// ```
pub fn[T] UnificationTable::redirect_root(
  self : UnificationTable[T],
  new_rank : Int,
  old_index : VarIndex,
  new_index : VarIndex,
  new_value : T,
) -> Unit {
  self.update(old_index, fn(old_value) { old_value.redirect(new_index) })
  self.update(new_index, fn(new_root_value) {
    new_root_value.root(new_rank, new_value)
  })
}

///|
/// Checks if two variables in the unification table belong to the same
/// equivalence class by comparing their root nodes.
///
/// Parameters:
///
/// * `first` : The index of the first variable.
/// * `second` : The index of the second variable.
///
/// Example:
///
/// ```moonbit
/// let table : UnificationTable[Int] = UnificationTable::new(capacity=2)
/// table.push(1)
/// table.push(2)
/// let _ = table.unite(table.index(0),table.index(1), 42)
/// inspect(
///   table.unioned(VarIndex::new(0), VarIndex::new(1)),
///   content="true",
/// )
/// ```
pub fn[T] UnificationTable::unioned(
  self : UnificationTable[T],
  index1 : VarIndex,
  index2 : VarIndex,
) -> Bool {
  return self.find(index1) == self.find(index2)
}

///|
/// Merges the equivalence classes of two variables in the unification table.
/// Utilizes a union-find data structure with rank-based optimization to keep the tree balanced.
/// After merging, assigns the specified new value to the root of the unified class.
///
/// Parameters:
///
/// * `table` : The unification table containing the variables.
/// * `first` : The index of the first variable to unite.
/// * `second` : The index of the second variable to unite.
/// * `value` : The new value to be assigned to the root of the merged
/// equivalence class.
///
/// Example:
///
/// ```moonbit
/// let table : UnificationTable[Int] = UnificationTable::new(capacity=2)
/// table.push(1)
/// table.push(2)
/// let root = table.unite(table.index(0),table.index(1), 42)
/// inspect(table.value(root).value, content="42")
/// ```
pub fn[T] UnificationTable::unite(
  self : UnificationTable[T],
  index1 : VarIndex,
  index2 : VarIndex,
  new_value : T,
) -> VarIndex {
  let root1 = self.find(index1)
  let root2 = self.find(index2)
  if root1 == root2 {
    return root1
  }
  let rank_a = self.get(root1.index).unwrap().rank
  let rank_b = self.get(root2.index).unwrap().rank
  if rank_a < rank_b {
    self.redirect_root(rank_b, root1, root2, new_value)
    return root2
  } else if rank_a > rank_b {
    self.redirect_root(rank_a, root2, root1, new_value)
    return root1
  } else {
    self.redirect_root(rank_a + 1, root2, root1, new_value)
    return root1
  }
}

///|
/// Finds the root (representative) of a variable in the union-find data structure,
/// applying path compression for optimization. During the search, updates the parent
/// pointers of all nodes along the path to point directly to the root.
///
/// Parameters:
///
/// * `index` : The index of the variable whose root needs to be found.
///
/// Returns the index of the root (representative) variable for the given variable index.
///
/// Example:
///
/// ```moonbit
/// let table : UnificationTable[Int] = UnificationTable::new(capacity=3)
/// table.push(1)
/// table.push(2)
/// table.push(3)
/// let _ = table.unite(table.index(0),table.index(1), 42)
/// let root = table.find(table.index(0))
/// inspect(root.index, content="0")
/// ```
pub fn[T] UnificationTable::find(
  self : UnificationTable[T],
  index : VarIndex,
) -> VarIndex {
  let value = self.value(index)
  if value.parent == index {
    return index
  }
  let redirect = value.parent
  let root = self.find(redirect)
  if root != redirect {
    self.update(index, fn(value) { value.redirect(root) })
  }
  return root
}

///|
/// Retrieves the root variable value (representative) for a given variable in the union-find data structure.
/// this function returns the actual `VarValue[T]` at the root node.
///
/// Parameters:
///
/// * `value` : The variable value whose root needs to be found.
///
/// Returns the variable value at the root (representative) node.
///
/// Example:
///
/// ```moonbit
/// let table : UnificationTable[Int] = UnificationTable::new(capacity=2)
/// table.push(1)
/// table.push(2)
/// let _ = table.unite(table.index(0), table.index(1), 42)
/// let value = table.get(0).unwrap()
/// let root = table.find_root(value)
/// inspect(root.value, content="42")
/// ```
pub fn[T] UnificationTable::find_root(
  self : UnificationTable[T],
  value : VarValue[T],
) -> VarValue[T] {
  let root_index = self.find(value.parent)
  return self.value(root_index)
}

// Snapshot

///|
/// Checks whether the unification table is currently in a snapshot state.
///
/// Example:
///
/// ```moonbit
/// let table : UnificationTable[Int] = UnificationTable::new(capacity=5)
/// let _ = table.start_snapshot()
/// assert_true(table.in_snapshot())
/// ```
pub fn[T] UnificationTable::in_snapshot(self : UnificationTable[T]) -> Bool {
  self.values.in_snapshot()
}

///|
/// Creates a new snapshot of the current state of the unification table. 
/// The snapshot captures the current state of all variable values,
/// allowing for later rollback or commit operations.
///
/// Example:
///
/// ```moonbit
/// let table : UnificationTable[Int] = UnificationTable::new(capacity=5)
/// table.push(42)
/// let snapshot = table.start_snapshot()
/// table.push(100)
/// table.rollback_to(snapshot)
/// inspect(table.values.length(), content="1")
/// ```
pub fn[T] UnificationTable::start_snapshot(
  self : UnificationTable[T],
) -> Snapshot {
  let snapshot = self.values.start_snapshot()
  new_snapshot(snapshot)
}

///|
/// Restores the unification table to a previous state captured by the given snapshot.
/// All changes made to the table after the snapshot was taken will be discarded.
/// 
///
/// Parameters:
///
/// * `snapshot` : A previously created snapshot representing the state
/// 
/// Example:
///
/// ```moonbit
/// let table : UnificationTable[Int] = UnificationTable::new(capacity=5)
/// table.push(42)
/// let snapshot = table.start_snapshot()
/// table.push(100)
/// table.rollback_to(snapshot)
/// inspect(table.values.length(), content="1")
/// ```
pub fn[T] UnificationTable::rollback_to(
  self : UnificationTable[T],
  snapshot : Snapshot,
) -> Unit {
  self.values.rollback_to(snapshot.snapshot)
}

///|
/// Commits the changes made after a snapshot, 
/// making them permanent and discarding the ability to rollback to that snapshot. 
///
/// Parameters:
///
/// * `snapshot` : A previously created snapshot that will be committed.
///
/// Example:
///
/// ```moonbit
/// let table : UnificationTable[Int] = UnificationTable::new(capacity=5)
/// table.push(42)
/// let snapshot = table.start_snapshot()
/// table.push(100)
/// table.commit(snapshot)
/// inspect(table.values.length(), content="2")
/// ```
pub fn[T] UnificationTable::commit(
  self : UnificationTable[T],
  snapshot : Snapshot,
) -> Unit {
  self.values.commit(snapshot.snapshot)
}

///|
pub fn[T] UnificationTable::op_get(
  self : UnificationTable[T],
  index : Int,
) -> VarValue[T] {
  return self.get(index).unwrap()
}

///|
pub fn[T] UnificationTable::op_set(
  self : UnificationTable[T],
  index : Int,
  value : VarValue[T],
) -> Unit {
  self.set(VarIndex::new(index), value)
}

///|
pub impl[T : Show] Show for VarValue[T] with output(self, logger : &Logger) {
  logger
  ..write_string("VarValue { value: ")
  ..write_object(self.value)
  ..write_string(", rank: ")
  ..write_object(self.rank)
  ..write_string(", parent: ")
  ..write_object(self.parent)
  ..write_string(" }")
}

///|
pub impl Show for VarIndex with output(self, logger : &Logger) {
  logger
  ..write_string("VarIndex { index: ")
  ..write_object(self.index)
  ..write_string(" }")
}

///|
pub impl[T : Show] Show for UnificationTable[T] with output(
  self,
  logger : &Logger,
) {
  logger.write_iter(
    self.values.values.iter(),
    prefix="UnificationTable[",
    suffix=" ]",
    sep=", ",
  )
}
