require 'csv'
require 'readline'
require './my_sqlite_request.rb'

def input_parse(input)
    if input[input.length - 1] != ';'
        puts "Request should end with a ';'"
        return
    end

    if input.include?('"')
        puts "Your string contains double quotes. Please use single quotes only"
        return
    end

    input = input.delete_suffix(';')

    @input = input.split
    if @input[0] == "SELECT"
        select
    elsif @input[0] == "INSERT" && @input[1] == "INTO"
        insert
    elsif @input[0] == "UPDATE"
        update
    elsif @input[0] == "DELETE" && @input[1] == "FROM"
        delete
    else
        puts "Request type not recognized"
        return
    end

end


def select
    
    is_join = :no
    is_where = :no
    is_order = :no

    if !@input.include?('FROM')
        puts "Invalid format"
    end
    
    #checks if table name is correct
    pos_from = @input.index('FROM')
    if @input[pos_from + 1] != @table_name.split('.').first
        puts "Table with such name does not exist"
        return
    end

    next_word = ['JOIN', 'WHERE', 'ORDER']

    if @input[pos_from + 1] != @input[@input.length - 1] && !next_word.include?(@input[pos_from + 2])
        puts "Invalid format"
        return
    end

    #gets column names that must be selected
    select_columns = @input[1..pos_from - 1].join(" ").split(',')
    select_columns = select_columns.map do |value|
        value.strip
    end

    #if there is a JOIN, gets second file name and JOIN columns
    if @input.include?('JOIN')

        is_join = :yes
        pos_join = @input.index('JOIN')
        pos_on = @input.index('ON')

        #checks if there is exactly one word between JOIN and ON
        if pos_join + 2 != pos_on
            puts "Invalid format"
            return
        end
        
        #gets second table name and checks if corresponding file exists
        second_table = @input[pos_join + 1]

        if File.exist?("#{second_table}.csv")
            second_table = "#{second_table}.csv"
        elsif File.exist?("#{second_table}.db")   
            second_table = "#{second_table}.db"
        else
            puts "JOIN file does not exist"
            return
        end

        #determines where the JOIN condition segment ends
        if @input.include?('WHERE')
            last_word = @input.index('WHERE') - 1
        elsif !@input.include?('WHERE') && @input.include?('ORDER')
            last_word = @input.index('ORDER') - 1
        else
            last_word = @input.length - 1
        end

        #gets names of JOIN columns
        join_columns = @input[pos_on + 1..last_word].join(" ").split('=')
        column_one = ''
        column_two = ''
        join_columns.each do |column|
            if column.split('.').last.strip == @table_name.split('.').first
                column_one = column.split('.').first.strip
            elsif column.split('.').last.strip == second_table.split('.').first
                column_two = column.split('.').first.strip
            else
                puts "One or more invalid JOIN column/table names"
                return
            end
        end

    end

    #if there is a WHERE, gets WHERE criteria
    if @input.include?('WHERE')

        is_where = :yes
        pos_where = @input.index('WHERE')

        if @input.include?('ORDER')
            last_word = @input.index('ORDER') - 1
        else
            last_word = @input.length - 1
        end

        where_criteria = @input[pos_where + 1..last_word].join(" ").split('=')
        where_criteria = where_criteria.map do |word|
            word.strip
        end 
        where_column = where_criteria.first
        where_condition = where_criteria.last.delete_prefix("'").delete_suffix("'")
    end

    #if there is an ORDER request, gets ORDER data
    if @input.include?('ORDER') && @input[@input.index('ORDER') + 1] == 'BY'       
        is_order = :yes

        pos_by = @input.index('BY')

        if @input[pos_by + 1] == @input[@input.length - 1]
            order_column = @input[pos_by + 1]
            order = :asc
        elsif @input[pos_by + 1] == @input[@input.length - 2]
            order_column = @input[pos_by + 1]
            if @input[pos_by + 2] == 'ASC'
                order = :asc
            elsif @input[pos_by + 2] == 'DESC'
                order = :desc
            else
                puts "Invalid order request"
                return
            end
        else 
            puts "Invalid format"
            return
        end

    end

    request = MySqliteRequest.new(@table_name).select(select_columns)
    request = request.join(column_one, second_table, column_two) if is_join == :yes  
    request = request.where(where_column, where_condition) if is_where == :yes
    request = request.order(order, order_column) if is_order == :yes
    request = request.run

end


def insert
    
    if @input[2] != @table_name.split('.').first
        puts "Table with such name does not exist"
        return
    end

    if @input[3] != "VALUES"
        puts "Invalid format"
        return
    end

    #makes an array of values that need to be inserted
    values = @input[4..@input.length - 1].join(' ')
    values = values.delete_prefix('(').delete_suffix(')')
    values = values.gsub(/,\s+'/, ",'")
    values = CSV.parse_line(values, liberal_parsing: true, quote_char: "'")
    values = values.map do |value|
        value.strip
    end
    insert_values = values.to_a
        
    #gets table headers that will become hash keys
    data = CSV.read(@table_name, headers: true, liberal_parsing: true, quote_char: '"')
    insert_keys = data.headers

    if insert_values.length != insert_keys.length 
        puts "Number of values does not match number of columns"
        return
    end

    #builds a hash from table headers and value array
    insert_hash = Hash[insert_keys.zip(insert_values)] 

    request = MySqliteRequest.new.insert(@table_name).values(insert_hash).run

end


def update

    if @input[1] != @table_name.split('.').first
        puts "Table with such name does not exist"
        return
    end

    if @input[2] != "SET" || !@input.include?("WHERE")
        puts "Invalid format"
        return
    end

    pos_where = @input.index("WHERE")

    #gets values for insertion between SET and WHERE, turns them into a hash
    values = @input[3..pos_where - 1].join(' ') 
    values = values.gsub(/=/, ',').gsub(/,\s+'/, ",'")
    values = CSV.parse_line(values, liberal_parsing: true, quote_char: "'")
    values = values.map do |value|
        value.strip
    end
    update_hash = Hash[*values]

    #gets the WHERE criteria for the row that should be updated
    where_criteria = @input[pos_where + 1..@input.length - 1].join(" ").split('=')
    where_criteria = where_criteria.map do |word|
        word.strip
    end  
    where_column = where_criteria.first
    where_condition = where_criteria.last.delete_prefix("'").delete_suffix("'")

    request = MySqliteRequest.new.update(@table_name).set(update_hash).where(where_column, where_condition).run   

end


def delete
    
    if @input[2] != @table_name.split('.').first
        puts "Table with such name does not exist"
        return
    end

    if @input[3] != "WHERE" || @input[5] != "=" 
        puts "Invalid format"
        return
    end

    #gets the WHERE criteria for the row that should be deleted
    where_criteria = @input[4..@input.length - 1].join(" ").split('=')
    where_criteria = where_criteria.map do |word|
        word.strip
    end  
    where_column = where_criteria.first
    where_condition = where_criteria.last.delete_prefix("'").delete_suffix("'")

    request = MySqliteRequest.new(@table_name).delete.where(where_column, where_condition).run    
end




if ARGV.length != 1 
    exit
end

@table_name = ARGV.first

if !File.exist?(@table_name)
    puts "File does not exist"
    return
end

puts "MySQLite version 0.1 #{Time.new.strftime("%Y-%m-%d")}"


while input = Readline.readline("my_sqlite_cli> ", true)
    if input.strip == "quit"
        exit
    end
    input_parse(input)
end