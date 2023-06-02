
using Random
using Printf


const TEAM_QUAL_MATCHES::Int = 12
const MIN_MATCH_GAP::Int = 2

#region Team

"""
    get_nummatches(team_qualmatches, num_teams)

Calculate the total number of qualification matches for an event.

`team_qualmatches` is the minimum number of matches that each individual
team will participate in.  `num_teams` is the number of teams competing
at the event.
"""
function get_nummatches(team_qualmatches::Integer, num_teams::Integer)
    return convert(Int, ceil(team_qualmatches * num_teams / 6))
end


mutable struct Team
    const number::Int
    matches::Int
    partners::Set{Int}
    opponents::Set{Int}
    mingap::Union{Int, Nothing}
    red::Int
    blue::Int
end

"""
    Team(number)

Create a team with an assigned number, but that is otherwise empty.
"""
Team(number::Integer) = Team(number, 0, Set(), Set(), nothing, 0, 0)

tostr(team::Team) = return @sprintf(
    "Team: %5u, Partners: %3u, Opponents %3u",
    team.number, length(team.partners), length(team.opponents))

teamrange(start::Int, stop::Int) = Dict(
    team_number => Team(team_number)
    for team_number in start:stop)

#endregion

#region Match

struct Match
    number::Int
    red::Vector{Team}
    blue::Vector{Team}
end

tostr(match::Match) = return join([
    "Match: $(match.number) ",
    "Red: $([team.number for team in match.red]) ",
    "Blue: $([team.number for team in match.blue])"], " ")

#endregion

#region Schedule

struct Schedule
    teams::Dict{Int, Team}
    matches::Vector{Match}
end

Schedule(teams::Dict{Int, Team}) = Schedule(teams, [])

tostr(schedule::Schedule) = (
    # "Teams: $(length(schedule.teams))" *
    join([tostr(match) for match in schedule.matches], "\n"))


"""
    pick6(teams_dict::Abstractdict, ineligible=[])

Randomly chooses six teams. Returns results as two vectors of 3 teams.

Teams passed to ineligible argument will not be selected.
"""
function pick6(teams_dict::AbstractDict,
               ineligible::Vector{Int}=Vector{Int}(undef, 0))
    team_list = Random.shuffle(
        [team for (team_number, team) in teams_dict
         if team_number ∉ ineligible])
    return team_list[1:3], team_list[4:6]
end

function get_ineligible_teams(schedule::Schedule)
    ineligible_teams = Vector{Team}(undef, 0)
    num_matches = length(schedule.matches)
    for prior_match in num_matches:-1:max(num_matches - MIN_MATCH_GAP + 1, 1)
        append!(ineligible_teams, schedule.matches[prior_match].red)
        append!(ineligible_teams, schedule.matches[prior_match].blue)
    end
    return [team.number for team in ineligible_teams]
end

function addmatch!(schedule::Schedule)
    matchnum = length(schedule.matches) + 1
    ineligible_teams = get_ineligible_teams(schedule)
    redteams, blueteams = pick6(schedule.teams, ineligible_teams)
    match = Match(matchnum, redteams, blueteams)
    push!(schedule.matches, match)
    updateteams!(match)
end

function addmatches!(schedule::Schedule, qty::Integer)
    for _ in 1:qty
        addmatch!(schedule)
    end
end


function updateteams!(match::Match)
    function updatealliance!(us, them, us_color::Symbol)
        for team in us
            union!(team.opponents, [tm.number for tm in them])
            union!(team.partners, [tm.number for tm in us
                                   if tm.number != team.number])
            team.matches += 1
            setproperty!(team, us_color, getproperty(team,us_color) + 1)
        end
    end
    updatealliance!(match.blue, match.red, Symbol("blue"))
    updatealliance!(match.red, match.blue, Symbol("red"))
end

#endregion


function main()
    teams = Dict(team_number => Event.Team(team_number)
                 for team_number in 1:Event.NUM_TEAMS)
    schedule = Event.Schedule(teams)
    Event.addmatch!(schedule)
    # println(schedule)
    println(schedule.matches)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end 