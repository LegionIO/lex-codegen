# frozen_string_literal: true

Sequel.migration do
  up do
    create_table?(:codegen_fixes) do
      primary_key :id
      String :fix_id, size: 64, null: false, unique: true, index: true
      String :gem_name, size: 128, null: false, index: true
      String :runner_class, size: 255
      String :branch, size: 255
      column :patch, :text
      String :status, size: 32, default: 'pending', null: false, index: true
      TrueClass :specs_passed, default: false
      column :spec_output, :text
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
    end
  end

  down do
    drop_table?(:codegen_fixes)
  end
end
