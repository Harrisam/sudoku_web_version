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

get '/' do 
	sudoku = random_sudoku
	session[:solution] = sudoku
	@current_solution = puzzle(sudoku)
	erb :index
end

get '/' do
  # save the current time into session
  session[:last_visit] = Time.now.to_s 
  "Last visit time has been recorded"
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
