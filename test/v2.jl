module PlotlyV2Tests

using Plotly

using Base.Test

statuscode(res) = res.status

M = Plotly  # simplify name

@testset "utils" begin
    @test M.basic_auth("foo", "pass") == "Basic Zm9vOnBhc3M="
end

@testset "api -- search" begin
    @test 200 == statuscode(M.search_list_raw("public:false flow"))
end

@testset "api -- files" begin
    # TODO: untested: file_content, file_drop_reference
    # NOTE: Not allowed to test these ones: file_copy, file_permanent_delete

    # TODO: come back to this and change to a plot once I have a plot here!!
    fid = "sglyon:257"  # plot `_jl_testing/myplot`

    get_fid_funcs = [
        M.file_retrieve_raw, M.file_path_raw, M.file_image_raw,
        M.file_sources_raw
    ]
    for func in get_fid_funcs
        @test 200 == statuscode(func(fid))
    end

    res_star_raw = M.file_star_raw(fid)
    @test 200 == statuscode(res_star_raw)
    res = M.get_json_data(res_star_raw)
    @test length(res["stars"]["results"]) > 0
    @test 204 == statuscode(M.file_remove_star(fid))

    @test 200 == statuscode(M.file_lookup_raw("_jl_testing/mygrid"))
    res = M.file_lookup("_jl_testing/mygrid")
    @test res["filename"] == "mygrid"

    @test 200 == statuscode(M.file_trash_raw(fid))
    @test 200 == statuscode(M.file_restore_raw(fid))
    @test 200 == statuscode(M.file_partial_update_raw(fid, world_readable=true))
    @test 200 == statuscode(M.file_update_raw(fid, world_readable=false))
end

@testset "api -- grids" begin
    # TODO: need to test grid_drop_reference, grid_permanent_delete, grid_upload

    fid = "sglyon:251"
    uid1 = "d6434f"
    uid2 = "8c7b60"

    res_retrieve = M.grid_retrieve_raw(fid)
    @test Dict(res_retrieve.headers)["Content-Type"] == "application/json"
    @test 200 == statuscode(res_retrieve)
    json_retrieve = M.get_json_data(res_retrieve)

    @test 200 == statuscode(M.grid_content_raw(fid))

    data = Dict(
        :cols => Dict(
            "first column" => Dict("data" => ["a", "b", "c"], "order" => 0),
            "second column" => Dict("data" => 1:3, "order" => 1),
        )
    )
    del_fn = join(rand('a':'z', 10), "")
    res = M.grid_create_raw(data, parent_path="_jl_testing", filename=del_fn)
    json_delete = M.get_json_data(res)
    fid_delete = json_delete["file"]["fid"]
    uid1_delete = json_delete["file"]["cols"][1]["uid"]
    uid2_delete = json_delete["file"]["cols"][2]["uid"]
    @test statuscode(res) == 201

    @test 201 == statuscode(M.grid_row(fid_delete, rand(2, 2)))

    new_col1 = [Dict("data" => ["d", "e", "f"])]
    res_put_col = M.grid_put_col_raw(fid_delete, new_col1, uid1_delete)

    cols_post = [Dict("name" => "third column", "data" => 4:6)]
    M.grid_post_col(fid_delete, cols_post)

    res2 = M.grid_destroy(fid_delete)
    @test statuscode(res2) == 204

    res_col = M.grid_get_col_raw(fid, uid1)
    @test 200 == statuscode(res_col)
    col_json = M.get_json_data(res_col)
    @test col_json["cols"][1]["data"] == ["a", "b", "c"]

    res_col = M.grid_get_col_raw(fid, uid1, uid2)
    @test 200 == statuscode(res_col)
    col_json = M.get_json_data(res_col)
    @test col_json["cols"][1]["data"] == ["a", "b", "c"]
    @test col_json["cols"][2]["data"] == [1, 2, 3]

    @test 200 == statuscode(M.grid_trash_raw(fid))
    @test 200 == statuscode(M.grid_restore_raw(fid))
    @test 200 == statuscode(M.grid_partial_update_raw(fid, world_readable=true))
    @test 200 == statuscode(M.grid_update_raw(fid, world_readable=false))


    res_lookup = M.grid_lookup_raw("_jl_testing/mygrid")
    @test 200 == statuscode(res_lookup)
    lookup_json = M.get_json_data(res_lookup)
    @test lookup_json["filename"] == "mygrid"
end

@testset "api -- plots" begin
    @test 200 == statuscode(M.plot_list_raw())
    @test 200 == statuscode(M.plot_feed_raw())

    fid = "sglyon:257"

    # test plot_create
    figure = Dict(
        "data" => [Dict(
            "type" => "bar", "xsrc" => "sglyon:251:d6434f", "ysrc" => "sglyon:251:8c7b60"
        )]
    )
    del_fn = join(rand('a':'z', 10), "")
    res_del = M.plot_create_raw(figure, parent_path="_jl_testing", filename=del_fn)
    @test 201 == statuscode(res_del)
    del_json = M.get_json_data(res_del)
    del_fid = del_json["file"]["fid"]

    res_update = M.plot_update_raw(del_fid, world_readable=true)
    @test 200 == statuscode(res_update)
    @test M.get_json_data(res_update)["world_readable"] == true

    res_p_update = M.plot_partial_update_raw(del_fid, world_readable=false)
    @test 200 == statuscode(res_p_update)
    @test M.get_json_data(res_p_update)["world_readable"] == false

    M.file_trash(del_fid)

    res_detail = M.plot_detail_raw(fid)
    @test 200 == statuscode(res_detail)
    @test M.get_json_data(res_detail)["filename"] == "myplot"

    res_content = M.plot_content_raw(fid)
    @test 200 == statuscode(res_content)
    @test M.get_json_data(res_content) == figure
end

@testset "api -- extras" begin
    # TODO
end
@testset "api -- folders" begin
    # TODO
end
@testset "api -- images" begin
    # TODO
end
@testset "api -- comments" begin
    # TODO
end
@testset "api -- plot-schema" begin
    # TODO
end

end
