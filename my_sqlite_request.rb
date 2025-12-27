require 'csv'

class MySqliteRequest
####      CONSTRUCTOR     #### 
    def initialize (table_name = nil)
        @type_of_request = :none
        @select_columns = []
        @table_name = table_name
        @join = :no
    end

    
####      SELECT QUERY BLOCK     ####  

    def from(table_name)
        if !@table_name
            @table_name = table_name
        else
            #if file name has already been entered at initialization
            raise "Can't enter file name multiple times"
        end
        self
    end

    def select(array)
        if @type_of_request == :none
            @type_of_request = :select
        else
            raise "Type of request already defined as #{@type_of_request}"
        end

        if !array.is_a?(Array) #handles cases when a string with one column name is passed
            if !array.strip.empty? && array != "*"
                @select_columns << array
            else
                @select_columns = []
            end
        else
            @select_columns = array
        end

        self
    end

    def join(column_on_db_a, filename_db_b, column_on_db_b) #ONLY APPLIES TO SELECT QUERY
        @join = :yes
        @second_table = filename_db_b
        @column_first = column_on_db_a
        @column_second = column_on_db_b
        self
    end

    def order(order, column_name) #ONLY APPLIES TO SELECT QUERY
        if @type_of_request != :select
            raise "Order only applies to a select request"
        end
        
        if order == :asc || order == :desc
            @order = order
        else
            raise "Order can only be :asc or :desc"
        end
        @order_column = column_name
        self
    end

####      END OF SELECT QUERY BLOCK     #### 



####      INSERT QUERY BLOCK     ####      
    def insert(table_name)
        if @type_of_request == :none
            @type_of_request = :insert
        else
            raise "Type of request already defined as #{@type_of_request}"        
        end
        @table_name = table_name     
        self
    end

    def values(data) #receives a hash =>
        @insert_data = data
        self
    end
####      END OF INSERT QUERY BLOCK     #### 


####      DELETE QUERY BLOCK     ####      
    def delete
        if @type_of_request == :none
            @type_of_request = :delete
        else
            raise "Type of request already defined as #{@type_of_request}"        
        end
        self
    end
####      END OF DELETE QUERY BLOCK     ####     

#### WHERE BLOCK - APPLIES TO SELECT, INSERT AND DELETE REQUESTS ####

    def where(column_name, criteria) #specifies the column in which to search for the criteria
        @where_column = column_name 
        @criteria = criteria     
        self
    end

#### END OF WHERE BLOCK ####



####      UPDATE QUERY BLOCK     ####   
    def update(table_name)
        if @type_of_request == :none
            @type_of_request = :update
        else
            raise "Type of request already defined as #{@type_of_request}"        
        end
        @table_name = table_name
        self
    end

    def set(data) #receives a hash with =>
        @update_data = data
        self
    end
####      END OF UPDATE QUERY BLOCK     #### 
    

    def run
        begin
        @data = CSV.read(@table_name, headers: true, liberal_parsing: true, quote_char: '"')

        if @type_of_request == :select
            if @join == :yes
                run_join
            end
            run_select
        elsif @type_of_request == :insert
            run_insert
        elsif @type_of_request == :delete
            run_delete
        elsif @type_of_request == :update
            run_update
        elsif @type_of_request == :none
            raise "Type of request not set"
        end

        rescue => e
            puts "#{e.message}"
            return nil
        end
    end


    def run_join
        
        data_second = CSV.read(@second_table, headers: true, liberal_parsing: true, quote_char: '"')

        if !@data.headers.include?(@column_first) || !data_second.headers.include?(@column_second)
            raise "One or more invalid column names provided for join"
        end

        joined_headers = @data.headers + data_second.headers

        joined_rows = []
        temp_row = []
          
        #turns the second column into a hash for faster matching
        lookup = {}
        data_second.each do |row|
            lookup[row[@column_second]] = row
        end

        #gets joined rows
        @data.each do |row|
            matching_row = lookup[row[@column_first]] 
            if matching_row
                temp_row = row.fields + matching_row.fields
                joined_rows << temp_row
                temp_row = []
            end
        end

        joined_data = CSV.generate do |csv|
            csv << joined_headers
            joined_rows.each do |row|
                csv << row
            end
        end

        @data = CSV.parse(joined_data, headers: true, liberal_parsing: true, quote_char: '"')
                
    end
    

    def run_select

        if @select_columns.empty?
            @select_columns = @data.headers
        end

        #checks if selected column names exist
        @select_columns.each do |column|
            if !@data.headers.include?(column)
                raise "Non existent column selected"
            end
        end

        if defined?(@where_column) && !@data.headers.include?(@where_column)
            raise "Unrecognized column name in where method"
        end        

        if defined?(@order)
            if @order == :asc
                @data = @data.sort_by { |row| row[@order_column] }
            else
                @data = @data.sort_by { |row| row[@order_column] }.reverse
            end
        end

        #finds the rows that need to get displayed
        temp_result = []
        result = [] 
        @data.each do |row|
            if !defined?(@where_column) || row[@where_column] == @criteria
                @select_columns.each do |column|
                    temp_result << row[column]
                end
                temp_result = temp_result.join(",")
                result << temp_result
                temp_result = []
            end
        end

        puts result
    end


    def run_update
        if !defined?(@update_data)
            raise "You haven't provided any data to update"
        end

        #checks if provided keys match existing column names
        @update_data.keys.each do |key| 
            if !@data.headers.include?(key)
                raise "One or more invalid keys provided"
            end
        end

        if !defined?(@where_column)
            raise "Criteria for update has not been defined"
        end

        if !@data.headers.include?(@where_column)
            raise "Unrecognized column name in where method"
        end

        @data.each do |row|
            if row[@where_column] == @criteria
                @update_data.keys.each do |key|
                    row[key] = @update_data[key]
                end
            end
        end

        overwrite_file
    end


    def run_insert
        if !defined?(@insert_data) 
            raise "You haven't provided any data to insert"
        end

        #checks if all provided keys match all column names
        if @insert_data.keys != @data.headers 
            raise "Some data is missing or incorrect, check if all keys match table header names and order"
        end
        @data << @insert_data.values
        overwrite_file
    end


    def run_delete
        if defined?(@where_column)
            if !@data.headers.include?(@where_column)
                raise "Unrecognized column name in where method"
            end

            @data.delete_if { |row| row[@where_column] == @criteria }
            overwrite_file
        else       
            raise "Deletion criteria not set"
        end
    end


    def overwrite_file #for insert, update and delete requests
        CSV.open(@table_name, "w", headers: true, write_headers: true) do |csv|
            csv << @data.headers
            @data.each do |row|
                csv << row
            end
        end
    end

end




#SELECT tests
#request = MySqliteRequest.new("nba_player_data.csv")
#request = request.select(["name", "year_start", "height"])
#request = request.insert("lalala")
#request = request.select([])
#request = request.select("    ")
#request = request.select("name")
#request = request.select("*")
#request = request.join("name", "nba_players.csv", "Player")
#request = request.where("year_start", "1969")
#request = request.order(:desc, "name")
#request.run


#INSERT tests
#request = MySqliteRequest.new
#request = request.insert("sample_one.csv")
#request = request.values({"name" => "Jane Doe", "year_start" => "2000", "year_end" => "2001", "position" => "top", "height" => "200", "weight" => "121", "birth_date" => "19 March, 1991", "college" => "Latvijas Universitate"})
#request = request.values({"year_start" => "2000", "name" => "John Doe", "year_end" => "2001", "position" => "top", "height" => "200", "weight" => "121", "birth_date" => "19 March, 1991", "college" => "Latvijas Universitate"})
#request.run


#DELETE tests
#request = MySqliteRequest.new("sample_one.csv")
#request = request.delete
#request = request.insert("lalala")
#request = request.delete.where("name", "Tom Abernethy")
#request = request.where("year_start", "1954")
#request.run


#UPDATE tests
#request = MySqliteRequest.new
#request = request.update("sample_one.csv")
#request = request.set({"year_start" => "29999", "height" => "hihihi", "college" => "Latvijas Universitate"})
#request = request.where("name", "Tariq Abdul-Wahad")
#request.run


#request = MySqliteRequest.new.update(csv_string).set({"year_start" => "2000", "height" => "hihihi", "college" => "Latvijas Universitate"}).where("name", "Alaa Abdelnaby").run
