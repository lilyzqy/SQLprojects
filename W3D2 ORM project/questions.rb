require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class Author
  attr_accessor :id, :fname, :lname
  def self.find_by_id(id)
    author = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
      *
      FROM
      authors
      WHERE
      id = ?
    SQL
    return nil if author.empty?
    Author.new(author.first)
  end

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def self.all
    data = QuestionsDatabase.instance.execute('SELECT * FROM authors')
    data.map{|datum|Author.new(datum)}
  end
end

class Question


end

class Follow
end

class Reply

end

class Like

end
