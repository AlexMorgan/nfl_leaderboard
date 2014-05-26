require 'shotgun'
require 'sinatra'
require 'csv'
require 'pry'

def read_from_csv(filename)
  stats = []
  CSV.foreach(filename, headers: true, header_converters: :symbol) do |row|
    stats << row.to_hash
  end
  stats
end

# Info from CSV to create a nested array of arrays for a team and their wins and losses ex: {"Patrits => {"wins' => 0, "losses" => 0},...}
def create_records(scores)
  team_stats = {}
  scores.each do |row|
    while !team_stats.has_key?(row[:home_team])
      team_stats[row[:home_team]] = {"wins" => 0, "losses" => 0}
    end
    while !team_stats.has_key?(row[:away_team])
      team_stats[row[:away_team]] = {"wins" => 0, "losses" => 0}
    end
  end
  team_stats
end

# Takes game infromation for the csv and adds a win or loss to corresponding scores
def game_results(scores, team_stats)
  scores.each do |game|
    if game[:home_score].to_i > game[:away_score].to_i
      team_stats[game[:home_team]]["wins"] += 1
      team_stats[game[:away_team]]["losses"] += 1
    else game[:home_score].to_i < game[:away_score].to_i
      team_stats[game[:away_team]]["wins"] += 1
      team_stats[game[:home_team]]["losses"] += 1
    end
  end
  team_stats
end

# Takes the accumulated information on team records and ranks them
def rank_teams(team_standings)
  team_standings.sort_by {|team, record| record["wins"] && record["losses"]}
end

# Create logic for the view that we want when we click on a team
def find_team(team_standings, team)
  team_to_find = nil
  team_standings.each do |team_name, team_stats|
    if team_name == team
      team_to_find = team_stats
    end
  end
  team_to_find
end

def find_played_games(scores, team)
  scores.select {|game| game[:home_team] == team || game[:away_team] == team}
end

scores = read_from_csv('stats.csv')

records = create_records(scores)

team_standings = game_results(scores, records)

#------------------------------------------ Routes ------------------------------------------
get '/' do
  @standings = rank_teams(team_standings)
  erb :index
end

get '/teams/:key' do
  @team = find_team(team_standings, params[:key])
  @games = find_played_games(scores, params[:key])
  erb :'teams/show'
end
