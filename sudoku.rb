require 'sinatra' # load sinatra
require './lib/cell'
require './lib/sudoku'


enable :sessions #sessions are disabled by default

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
	sudoku
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
	session[:check_solution] = nil
end

get '/random' do 
	sudoku = random_sudoku
	prepare_to_check_solution
	generate_new_puzzle_if_necessary
	session[:solution] = sudoku
	@current_solution = puzzle(sudoku)
	@solution = session[:solution]
	@puzzle = session[:puzzle]
	erb :index
end

get '/time' do
  # save the current time into session
  session[:last_visit] = Time.now.to_s 
  "Last visit time has been recorded"
end 

get'/' do
	prepare_to_check_solution
	generate_new_puzzle_if_necessary
	@current_solution = session[:current_solution] || session[:puzzle]
	@solution = session[:solution]
	@puzzle = session[:puzzle]
	
	erb :index
end

get '/solution' do
	@current_solution = session[:solution]
	erb :index
end

get '/last-visit' do
	# get the last visited time from the session
	"Previous visit to homepage: #{session[:last_visit]}"
	session[:last_visit] = nil
end

post '/' do
	cells = params["cell"]
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

				
