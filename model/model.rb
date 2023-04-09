require 'sqlite3'
require 'date'


# The Model class handle database interactions for the website
#
class Model

  # Load a SQLite3 database into the Model object
  #
  # @param [String] database_name The name of the SQLite3 database to load
  def loaddatabase(database_name)
    @db = SQLite3::Database.new(database_name)
    @db.results_as_hash = true
  end

  # Get all objects from the database
  #
  # @return [Array<Hash>] An array of all objects in the database
  def get_objects
    @db.execute("SELECT * FROM objects")
  end

  # Get all comments from the database
  #
  # @return [Array<Hash>] An array of all comments in the database
  def get_comments
    @db.execute("SELECT * FROM comments")
  end

  # Record login attempt
  #
  # @param [String] The username of the user attempted to log into.
  def record_login_attempt(username)
    @db.execute('INSERT INTO loginattempts (username, timestamp) VALUES (?,?)', username, Time.now.strftime('%Y-%m-%d %H:%M:%S'))
    # @db.execute[:login_attempts].insert(username: username, timestamp: Time.now)
  end

  # Returns the most recent login attempt for the specified username.
  #
  # @param username [String] The username to fetch the login attempt for.
  # @return [Hash, nil] A hash representing the most recent login attempt for the specified username,
  #   or nil if no login attempts were found for the username.
  #
  # The hash returned by this function contains the following keys:
  # - :id (Integer) - The unique ID of the login attempt.
  # - :username (String) - The username associated with the login attempt.
  # - :timestamp (String) - The timestamp of the login attempt in the format "YYYY-MM-DD HH:MM:SS".
  def last_login_attempt(username)
    @db.execute("SELECT * FROM loginattempts WHERE username = ? ORDER BY timestamp DESC LIMIT 1", username).first
  end

  # Get all objects in a specific class from the database
  #
  # @param [String] object_class The class of objects to fetch
  # @return [Array<Hash>] An array of all objects in the specified class
  def get_objects_by_class(object_class)
    @db.execute("SELECT * FROM objects WHERE class = ?", object_class)
  end

  # Get a specific object from the database by ID
  #
  # @param [Integer] object_id The ID of the object to fetch
  # @return [Hash] The object with the specified ID
  def get_object(object_id)
    @db.execute("SELECT * FROM objects WHERE id = ?", object_id).first
  end

  # Get a specific comment from the database by ID
  #
  # @param [Integer] comment_id The ID of the comment to fetch
  # @return [Hash] The comment with the specified ID
  def get_comment(comment_id)
    @db.execute("SELECT * FROM comments WHERE comment_id = ?", comment_id).first
  end

  # Add an object to the database
  #
  # @param [String] name The name of the object to add
  # @param [Integer] quantity The quantity of the object to add
  # @param [String] object_class The class of the object to add
  # @param [String] status The status of the object to add
  # @param [String] author The author of the object to add
  def add_object(name, quantity, object_class, status, author)
    @db.execute('INSERT INTO objects (name, quantity, class, status, author) VALUES (?,?,?,?,?)', name, quantity, object_class, status, author)
  end

  # Update an object in the database
  #
  # @param [Integer] object_id The ID of the object to update
  # @param [String] status The new status of the object
  # @param [Integer] quantity The new quantity of the object
  # @param [String] object_class The new class of the object
  def update_object(object_id, status, quantity, object_class)
    @db.execute("UPDATE objects SET status = ?, quantity = ?, class = ? WHERE id = ?", status, quantity, object_class, object_id)
  end

  # Delete an object from the database
  #
  # @param [Integer] object_id The ID of the object to delete
  def delete_object(object_id)
    @db.execute("DELETE FROM objects WHERE id = ?", object_id)
    @db.execute("DELETE FROM comments WHERE object_id = ?", object_id)
  end

  # Add a comment to the database
  #
  # @param [Integer] object_id The ID of the object the comment is associated with
  def add_comment(object_id, author_id, text, date)
    @db.execute('INSERT INTO comments (object_id, author_id, text, date) VALUES (?,?,?,?)', object_id, author_id, text, date)
  end

  # Deletes a comment with a given comment ID from the database.
  # 
  # @param comment_id [Integer] the ID of the comment to be deleted
  def delete_comment(comment_id)
    @db.execute("DELETE FROM comments WHERE comment_id = ?", comment_id)
  end

  # Retrieves all comments associated with a given object ID from the database.
  #
  # @param object_id [Integer] the ID of the object whose comments are to be retrieved
  # @return [Array] an array of hashes representing the retrieved comments
  def get_comments_by_object_id(object_id)
    @db.execute("SELECT comments.*, users.name FROM comments INNER JOIN users ON comments.author_id = users.id WHERE object_id = ?", object_id)
  end

  # Retrieves the user with the given username from the database.
  #
  # @param username [String] the username of the user to be retrieved
  # @return [Hash] a hash representing the retrieved user
  def get_user_by_name(username)
    @db.execute("SELECT * FROM users WHERE name = ?", username).first
  end

  # Adds a new user to the database.
  #
  # @param username [String] the username of the new user
  # @param password_digest [String] the encrypted password of the new user
  # @param join_date [String] the join date of the new user
  # @param rank [String] the rank of the new user
  def add_user(username, password_digest, join_date, rank)
    @db.execute('INSERT INTO users (name, encryptedpassword, join_date, rank) VALUES (?,?,?,?)', username, password_digest, join_date, rank)
  end

end
