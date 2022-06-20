class RenameTutorialsAsGuides < ActiveRecord::Migration[5.2]
  def self.up
    rename_table :tutorials, :guides
  end

  def self.down
    rename_table :guides, :tutorials
  end
end
