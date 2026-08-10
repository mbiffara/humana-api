# Map old experience kinds and retreat types to the new wellness-focused values.
# Old experience kinds: retreat, masterclass, corporate
# Old retreat types:    wellness, spiritual, corporate, adventure, medical
# New unified values:   wellness, spiritual, liderazgo_mujeres, constelaciones_familiares,
#                       breathwork, neurociencia, kabbalah, mindfulness
class UpdateExperienceAndRetreatTypes < ActiveRecord::Migration[8.0]
  def up
    # Experience kinds
    execute <<~SQL
      UPDATE experiences SET kind = 'wellness'   WHERE kind = 'retreat';
      UPDATE experiences SET kind = 'mindfulness' WHERE kind = 'corporate';
      UPDATE experiences SET kind = 'kabbalah'    WHERE kind = 'masterclass';
    SQL

    # Retreat types
    execute <<~SQL
      UPDATE retreats SET retreat_type = 'mindfulness'  WHERE retreat_type = 'corporate';
      UPDATE retreats SET retreat_type = 'breathwork'   WHERE retreat_type = 'adventure';
      UPDATE retreats SET retreat_type = 'neurociencia' WHERE retreat_type = 'medical';
    SQL
  end

  def down
    # Experience kinds
    execute <<~SQL
      UPDATE experiences SET kind = 'retreat'     WHERE kind = 'wellness';
      UPDATE experiences SET kind = 'corporate'   WHERE kind = 'mindfulness';
      UPDATE experiences SET kind = 'masterclass' WHERE kind = 'kabbalah';
    SQL

    # Retreat types
    execute <<~SQL
      UPDATE retreats SET retreat_type = 'corporate' WHERE retreat_type = 'mindfulness';
      UPDATE retreats SET retreat_type = 'adventure' WHERE retreat_type = 'breathwork';
      UPDATE retreats SET retreat_type = 'medical'   WHERE retreat_type = 'neurociencia';
    SQL
  end
end
