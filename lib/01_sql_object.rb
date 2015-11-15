require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    @columns ||= DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        "#{table_name}"
    SQL

    @columns.first.keys.map(&:to_sym)

  end

  def self.finalize!
    columns.each do |column|

      define_method("#{column}") do
        attributes[column]
      end

      define_method("#{column}=") do |value|
        attributes[column] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        "#{table_name}"
    SQL

    self.parse_all(results)

  end

  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  def self.find(id)
    # debugger
    found = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        "#{table_name}"
      WHERE
        id = ?
    SQL

    self.parse_all(found).first
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      if self.class.columns.include?(attr_name.to_sym)
        self.send "#{attr_name}=", value
      else
        raise "unknown attribute '#{attr_name}'"
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    values = self.class.columns.map do |col|
      self.send "#{col}"
    end

    values
  end

  def insert

    col_names = self.class.columns.join(", ")
    question_marks = (["?"] * attribute_values.count).join(", ")
    question_marks_string = "(#{question_marks})"

    insert = DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        #{question_marks_string}
    SQL

    self.id = DBConnection.last_insert_row_id

  end

  def update
    set_line = self.class.columns.map do |col|
      "#{col} = ?"
    end

    set_line = set_line.join(", ")
    debugger

    update = DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        id = ?
    SQL

  end

  def save
    id.nil? ? insert : update
  end
end
