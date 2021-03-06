require 'sinatra'
require 'sinatra/partial'
require 'rack-flash'
require './lib/cell'
require './lib/sudoku'

use Rack::Flash
enable :sessions #sessions are disabled by default
set :session_secret, "Hiya"
set :partial_template_engine, :erb # load sinatra

configure :production do
	require 'newrelic_rpm'
end

def random_sudoku
	#we're using 9 numbers, 1 to 9, and 72 zeros as an input
	#it's obvious there may be no clashes as all numbers are unique
	seed = (1..9).to_a.shuffle + Array.new(81-9, 0)
	sudoku = Sudoku.new(seed.join)
	#then we solve this (really hard!) sudoku
	sudoku.solve!
	#and give the output to the view as an array of chars
	sudoku.to_s.chars
end

#this method removes some digits from the solution to create a puzzle
def puzzle(sudoku)
	# this method is yours to implement
	random = (0..81).to_a.sample(25)
	@puzzled = []
	sudoku.each_with_index do |element,index|
		if random.include?(index) then @puzzled.push(0)
		else @puzzled.push(element) end 
		end 
	@puzzled 
end

def generate_new_puzzle_if_necessary
	return if session[:current_solution]
	sudoku = random_sudoku
	session[:solution] = sudoku
	session[:puzzle] = puzzle(sudoku)
	session[:current_solution] = session[:puzzle]
end

def prepare_to_check_solution
	@check_solution = session[:check_solution]
	if @check_solution
		flash[:notice] = "Incorrect values are highlighted in purple"
	end
	session[:check_solution] = nil
end

def box_order_to_row_order(cells)
	boxes = cell.each_slice(9).to_a
	(0..8).to_a.inject([]) do |memo, i|
		first_box_index = i / 3 * 3
		three_boxes = boxes[first_box_index, 3]
		three_rows_of_three = three_boxes.map do |box| 
			row_number_in_a_box = i % 3
			first_cell_in_the_row_index = row_number_in_a_box * 3
			box[first_cell_in_the_row_index, 3]
		end
		memo += three_rows_of_three.flatten
	end
end

# get '/random' do 
# 	sudoku = random_sudoku
# 	prepare_to_check_solution
# 	generate_new_puzzle_if_necessary
# 	session[:solution] = sudoku
# 	@current_solution = puzzle(sudoku)
# 	@solution = session[:solution]
# 	@puzzle = session[:puzzle]
# 	erb :index
# end

get '/time' do
  # save the current time into session
  session[:last_visit] = Time.now.to_s 
  "Last visit time has been recorded"
end 

get '/' do
	prepare_to_check_solution
	generate_new_puzzle_if_necessary
	@current_solution = session[:current_solution] || session[:puzzle]
	@solution = session[:solution]
	@puzzle = session[:puzzle]
	erb :index
end

get '/solution' do
	redirect to("/") if session[:solution].nil?
	@current_solution = session[:solution]
	@solution = session[:solution]
	@puzzle = session[:puzzle]
	erb :index
end

get '/last-visit' do
	# get the last visited time from the session
	"Previous visit to homepage: #{session[:last_visit]}"
	session[:last_visit] = nil
end

get '/reset' do
	session[:solution] = nil
	session[:puzzle] = nil
	session[:current_solution] = nil
	session[:check_solution] = nil 
	session[:last_visit] = nil
	redirect to("/")
end


post '/' do
  boxes = params["cell"].each_slice(9).to_a
  cells = (0..8).to_a.inject([]) {|memo, i|
  memo += boxes[i/3*3, 3].map{|box| box[i%3*3, 3] }.flatten
  }
  session[:current_solution] = cells.map{|value| value.to_i }.join
  session[:check_solution] = true
  redirect to("/")
end

helpers do

	def colour_class(solution_to_check, puzzle_value, current_solution_value, solution_value)
		must_be_guessed = puzzle_value == 0
		tried_to_guess = current_solution_value.to_i != 0
		guessed_incorrectly = current_solution_value != solution_value

		if solution_to_check &&
			must_be_guessed &&
			tried_to_guess &&
			guessed_incorrectly
			'incorrect'
		elsif !must_be_guessed
			'value-provided'
		end
	end

	def cell_value(value)
		value.to_i == 0 ? '' : value
	end
end

				
