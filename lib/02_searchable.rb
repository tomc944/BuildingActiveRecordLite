require_relative 'db_connection'
require_relative '01_sql_object'
require 'byebug'

module Searchable
  def where(params)
    parameters = params.map { |col, value| "#{col} = '#{value}'"}
    conditions = parameters.join(" AND ")

    output = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{conditions}
    SQL

    parse_all(output)
  end
end

class SQLObject
  extend Searchable
end
