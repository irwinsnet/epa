module MeasureCalcs

using DataFrames
using SQLite


function getmeasures(sqlpath::String)
    db = SQLite.DB(sqlpath)
        return DataFrames.DataFrame(
            SQLite.DBInterface.execute(
                db,
                "SELECT * FROM Measures;"));
end


function nummatches(measures::DataFrames.DataFrame)
    return measures |>
        df -> select(df, ["match", "team"]) |>
        unique |>
        df -> groupby(df, "team") |>
        df -> combine(df, nrow) |>
        df -> rename(df, :nrow => "num_matches")
end

function hitsums(measures::DataFrames.DataFrame)
    hit_types = ["count", "boolean", "rating"]
    return measures |>
        df -> filter(row -> in(row.measure_type, hit_types), df) |>
        df -> groupby(df, ["team", "phase", "task", "measure_type"]) |>
        df -> combine(df, :hit => sum)
end

function hitmeans(hitsums_df::DataFrames.DataFrame,
                  nummatches_df::DataFrames.DataFrame)
    hitmeans_df = innerjoin(nummatches_df, hitsums_df, on=:team)
    hitmeans_df[:, :hit_mean] .= hitmeans_df.hit_sum ./ hitmeans_df.num_matches
    return hitmeans_df 
end

end


function catsums(measures::DataFrames.DataFrame)
    return measures |>
        df -> filter(row -> row.measure_type == "categrical", df) |>
        df -> groupby(df, ["team", "phase", "task", "cat", "measure_type"]) |>
        df -> combine(df, nrow) |>
        df -> rename(df, :nrow => "cat_sum")
end

function catmeans(catsums_df::DataFrames.DataFrame,
                  nummatches_df::DataFrames.DataFrame)
    catmeans_df = innerjoin(nummatches_df, catsums_df, on=:team)
    catmeans_df[:, :cat_mean] .= catmeans_df.cat_sum ./ catmeans_df.num_matches
    return catmeans_df
end