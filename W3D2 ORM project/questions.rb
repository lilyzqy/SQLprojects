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

  def find_by_name(fname, lname)
    author = QuestionsDatabase.instance.execute(<<-SQL,fname,lname)
    SELECT
    *
    FROM
    authors
    WHERE
    fname = ? AND lname = ?
    SQL
    return nil if author.empty?
    User.new(author.first)
  end

  def authored_replies
    Reply.find_by_author_id(self.id)
  end

  def authored_questions
    Question.find_by_author_id(self.id)
  end

  def followed_questions
    Question.followed_questions_for_user_id(self.id)
  end

  def save
    if @id
      QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname,@id)
      UPDATE authors
      (fname,lname)
      SET
      (?,?)
      WHERE
      id = ?
      SQL
    else
      QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname)
      INSERT INTO authors
      (fname,lname)
      VALUEs
      (?,?)
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id
    end
  end
end

class Question
  attr_accessor :id , :title, :body, :author_id

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end

  def self.all
    data = QuestionsDatabase.instance.execute('SELECT * FROM questions')
    data.map{|datum|Question.new(datum)}
  end

  def self.find_by_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL
    return nil if question.empty?
    Question.new(question.first)
  end

  def author
    Author.find_by_id(self.author_id)
  end

  def replies
    Reply.find_by_question_id(self.id)
  end

  def followers
    Question.followers_for_question_id(self.id)
  end

  def find_by_author_id(author_id)
    ques = QuestionsDatabase.instance.execute(<<-SQL,author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        author_id = ?
    SQL
    return nil if ques.empty?
    ques.map{|que| Question.new(que)}
  end

  def save
    if @id
      QuestionsDatabase.instance.execute(<<-SQL, @title, @body,@author_id,@id)
      UPDATE questions
      (title,body,author_id)
      SET
      (?,?,?)
      WHERE
      id = ?
      SQL
    else
      QuestionsDatabase.instance.execute(<<-SQL, @title, @body,@author_id)
      INSERT INTO questions
      (title,body,author_id)
      VALUEs
      (?,?,?)
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id
    end
  end
end

class Reply
  attr_accessor :id , :question_id, :body, :author_id, :parent_reply_id

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @body = options['body']
    @author_id = options['author_id']
    @parent_reply_id = options['parent_reply_id']
  end

  def self.all
    data = QuestionsDatabase.instance.execute('SELECT * FROM replies')
    data.map{|datum|Reply.new(datum)}
  end

  def self.find_by_id(id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
      *
      FROM
      replies
      WHERE
      id = ?
    SQL
    return nil if reply.empty?
    Reply.new(reply.first)
  end

  def find_by_user_id(user_id)
    res = QuestionsDatabase.instance.excute(<<-SQL, user_id)
    SELECT
    *
    FROM
    replies
    WHERE
    author_id = ?
    SQL
    return nil if res.empty?
    res.map{|r|Reply.new(r)}
  end

  def find_by_question_id(question_id)
    res = QuestionsDatabase.instance.execute(<<-SQL,question_id)
    SELECT
    *
    FROM
    replies
    WHERE
    question_id = ?
    SQL
    return nil if res.empty?
    res.map{|r|Reply.new(r)}
  end

  def author
    Author.find_by_id(self.author_id)
  end

  def question
    Question.find_by_id(self.question_id)
  end

  def parent_reply
    Reply.find_by_id(self.parent_reply_id)
  end

  def child_replies
    res = QuestionsDatabase.instance.execute(<<-SQL, @id)
      SELECT
      *
      FROM
      replies
      WHERE
      parent_reply_id = ?
    SQL
    return nil if res.empty?
    res.map{|r| Reply.new(r)}
  end


  def save
    if @id
      QuestionsDatabase.instance.execute(<<-SQL, @question_id, @body,@author_id,@parent_reply_id,@id)
      UPDATE replies
      (question_id,body,author_id,parent_reply_id)
      SET
      (?,?,?,?)
      WHERE
      id = ?
      SQL
    else
      QuestionsDatabase.instance.execute(<<-SQL, @question_id, @body,@author_id,@parent_reply_id)
      INSERT INTO replies
      (question_id,body,author_id,parent_reply_id)
      VALUEs
      (?,?,?,?)
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id
    end
  end
end

class QuestionFollow
  attr_accessor :id, :question_id, :follower_id

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @follower_id = options['follower_id']
  end

  def self.followers_for_question_id(question_id)
    auth = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
      authors.id,fname,lname
      FROM
      authors
      JOIN
      question_follows ON authors.id = question_follows.follower_id
      WHERE
      question_id = ?
    SQL
    return nil if auth.empty?
    auth.map{|auth|Author.new(auth)}
  end

  def self.followed_questions_for_user_id(user_id)
    ques = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
      questions.id,title,body,author_id
      FROM
      questions
      JOIN
      question_follows ON questions.id = question_follows.question_id
      WHERE
      follower_id = ?
    SQL
    return nil if ques.empty?
    ques.map{|q|Question.new(q)}
  end

  def save
    if @id
      QuestionsDatabase.instance.execute(<<-SQL, @question_id,@follower_id,@id)
      UPDATE replies
      (question_id,follower_id)
      SET
      (?,?)
      WHERE
      id = ?
      SQL
    else
      QuestionsDatabase.instance.execute(<<-SQL, @question_id,@follower_id,)
      INSERT INTO replies
      (question_id,follower_id)
      VALUEs
      (?,?)
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id
    end
  end
end
