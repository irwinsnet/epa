import simfrc as sf


teams = sf.teamrange(1, 30)

@testset "teams" begin
    @test sf.Team == typeof(teams[1])
    for team_number = 1:30
        @test haskey(teams, team_number)
    end
    @test !haskey(teams, 0)
    @test !haskey(teams, 31)
end

@testset "pick6" begin
    match_teams = sf.pick6(teams)
    @test Tuple{Vector{simfrc.Team}, Vector{simfrc.Team}} == typeof(match_teams)
    @test 2 == length(match_teams)
    @test sf.Team == typeof(match_teams[1][1])

    ineligible_teams = collect(1:10)
    for _ in 1:10
        match_teams = sf.pick6(teams, ineligible_teams)
        for team in vcat(match_teams[1], match_teams[2])
            @test team.number > 10
            @test team.number <= 30
        end
    end
end


schedule = sf.Schedule(teams)


@testset "schedule" begin
    @test 30 == length(schedule.teams)
    # Add first match
    sf.addmatch!(schedule)
    @test 1 == length(schedule.matches)
    match1 = schedule.matches[1]
    red1 = match1.red[1]
    @test 3 == length(red1.opponents)
    @test 2 == length(red1.partners)
    match1_teams = vcat(
        [team.number for team in match1.red],
        [team.number for team in match1.blue],
    )
    # Add second match
    @test match1_teams == sf.get_ineligible_teams(schedule)
    sf.addmatch!(schedule)
    @test 2 == length(schedule.matches)
    @test 12 == length(sf.get_ineligible_teams(schedule))
    match2 = schedule.matches[2]
    blue2 = match2.blue[2]
    @test 3 == length(blue2.opponents)
    @test 2 == length(blue2.partners)
    # Add third match
    sf.addmatch!(schedule)
    @test 3 == length(schedule.matches)
    @test 12 == length(sf.get_ineligible_teams(schedule))
end











@testset "matches" begin
    @test 50 == sf.get_nummatches(12, 25)
end