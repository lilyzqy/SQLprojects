CREATE TABLE authors(
  id INTEGER PRIMARY KEY,
  fname TEXT,
  lname TEXT
);

CREATE TABLE questions(
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  author_id INTEGER NOT NULL,

  FOREIGN KEY (author_id) REFERENCES authors(id)
);

CREATE TABLE question_follows(
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  follower_id INTEGER NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (follower_id) REFERENCES authors(id)
);

CREATE TABLE replies(
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  parent_reply_id INTEGER ,
  author_id INTEGER NOT NULL,
  body TEXT NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (author_id) REFERENCES authors(id),
  FOREIGN KEY (parent_reply_id) REFERENCES replies(id)
);

CREATE TABLE question_likes(
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  liker_id INTEGER NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (liker_id) REFERENCES authors(id)
);

INSERT INTO
  authors(fname,lname)
VALUES
  ('Lily','Yang'),
  ('Leon','Chen'),
  ('Ethan','Chen');

INSERT INTO
  questions(title,body,author_id)
VALUES
  ('What is ?','Does anyone know?',(SELECT id FROM authors WHERE fname ='Lily' AND lname = 'Yang')),
  ('Confuse about','I don''t know',(SELECT id FROM authors WHERE fname ='Ethan' AND lname = 'Chen'));
