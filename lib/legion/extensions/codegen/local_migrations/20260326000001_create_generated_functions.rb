# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:generated_functions) do
      String :id, primary_key: true
      String :gap_id
      String :gap_type
      String :tier
      String :name, null: false
      String :file_path
      String :spec_path
      String :status, default: 'pending'
      Float :confidence, default: 0.0
      Integer :attempt_count, default: 0
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :approved_at
      DateTime :last_used_at
      Integer :usage_count, default: 0

      index :status
      index :gap_id
    end
  end
end
