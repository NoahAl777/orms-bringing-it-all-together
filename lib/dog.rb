require_relative "../config/environment.rb"

class Dog

  attr_accessor :name, :breed, :id

  def initialize(id:nil,name:,breed:)
    @id = id
    @name = name
    @breed = breed
  end

  def self.create_table
    sql = "CREATE TABLE IF NOT EXISTS dogs (id INTEGER PRIMARY KEY, name TEXT, breed TEXT)"
    DB[:conn].execute(sql)
  end

  def self.drop_table
    sql = "DROP TABLE IF EXISTS dogs"
    DB[:conn].execute(sql)
  end

  def save #Updates if exists, else inserts new into table
    if self.id
      self.update
    else
      sql = <<-SQL
        INSERT INTO dogs (name,breed)
        VALUES (?,?)
      SQL
      DB[:conn].execute(sql,self.name,self.breed)
      @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
  end
  self #returns an instance of the class
end

  def self.create(name:,breed:)#hash of attributes
    dog = Dog.new(name: name, breed: breed) #creates new instance with attributes
    dog.save #saves new object to database
    dog #calls itself
  end

  def self.new_from_db(row)#requires row with values in db
    id = row[0] #assigns db values to instance variables
    name = row[1]
    breed = row[2]
    self.new(id: id, name: name, breed: breed)#creates an instance with these corresponding attributes
  end

  def self.find_by_id(id)
    sql = <<-SQL
    SELECT * FROM dogs
    WHERE id = ?
    LIMIT 1
    SQL
    DB[:conn].execute(sql,id).map do |row|
      self.new_from_db(row)
    end.first
  end

  def self.find_or_create_by(name:,breed:)
    sql = <<-SQL
      SELECT * FROM dogs
      WHERE name = ?
      AND breed = ?
      LIMIT 1
    SQL
    dog = DB[:conn].execute(sql,name,breed)

    if !dog.empty? #if exists
      dog_data = dog[0] #matches dog_data to row id
      dog = Dog.new(id: dog_data[0], name: dog_data[1], breed: dog_data[2]) #creates new instance with attributes thrugh hash values
    else
      dog = self.create(name: name, breed: breed) #if instance doesnt exist
    end
    dog #calls dog
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT * FROM dogs
      WHERE name = ?
      LIMIT 1
    SQL
    DB[:conn].execute(sql,name).map do |row|
      self.new_from_db(row)
    end.first
  end

  def update
    sql = "UPDATE dogs SET name = ?, breed = ? WHERE id = ?"
    DB[:conn].execute(sql, self.name, self.breed, self.id)
  end
end

