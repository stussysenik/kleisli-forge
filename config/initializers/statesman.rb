Statesman.configure do
  storage_adapter Statesman::Adapters::ActiveRecord
end

# Rails 8.1 raises ColumnNotSerializableError when `serialize` is called on
# native jsonb columns. Statesman 12.x unconditionally calls
# `serialize :metadata, coder: JSON` in ActiveRecordTransition's `included`
# block. The `serialize` call registers a deferred type decoration that
# raises when the schema loads. Fix: replace the included block to skip
# `serialize` entirely (our metadata columns are all native jsonb).
require "statesman/adapters/active_record_transition"

Statesman::Adapters::ActiveRecordTransition.instance_variable_set(:@_included_block, proc {
  # Do NOT call serialize — our metadata columns are native PostgreSQL jsonb.
  # Rails handles jsonb (de)serialization automatically.

  class_attribute :updated_timestamp_column
  self.updated_timestamp_column =
    Statesman::Adapters::ActiveRecordTransition::DEFAULT_UPDATED_TIMESTAMP_COLUMN
})
