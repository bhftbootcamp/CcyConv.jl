using CcyConv.Pathfinding

@testset "Pathfinding algorithm" begin
    for pathfinding_module in [
        CcyConv.Pathfinding.DFSPathFinder,
        CcyConv.Pathfinding.DFSPathFinder_v2,
        CcyConv.Pathfinding.ExtremumPathFinder,
        #CcyConv.Pathfinding.SpanningTreePathFinder, # CcyConv.Pathfinding.SpanningTreePathFinder |   33     9     42  2.1s
        #CcyConv.Pathfinding.BellmanFordPathFinder,
        #CcyConv.Pathfinding.AdvantageousPathFinder
    ]
        conv_max = pathfinding_module.conv_max
        conv_min = pathfinding_module.conv_min

        @testset "$pathfinding_module" begin
            my_graph = FXGraph()

            append!(
                my_graph,
                [
                    Price("A", "F", 50.0),
                    Price("A", "B", 5.0),
                    Price("A", "C", 4.0),
                    Price("B", "D", 4.0),
                    Price("B", "C", 1.0),
                    Price("C", "B", 2.0),
                    Price("C", "D", 2.0),
                    Price("C", "E", 2.0),
                    Price("D", "F", 2.0),
                    Price("E", "F", 1.0),
                    Price("X", "Y", 42.0),
                    Price("Y", "X", 24.0),
                ],
            )

            @testset "Test №1: A -> F" begin
                a_star_rate = conv_a_star(my_graph, "A", "F")
                max_rate = conv_max(my_graph, "A", "F")
                min_rate = conv_min(my_graph, "A", "F")

                @test max_rate |> conv_value ≈ 64.0
                @test conv_value(a_star_rate) < conv_value(max_rate)
                @test length(conv_chain(a_star_rate)) <= length(conv_chain(max_rate))
                @test max_rate |> conv_chain == [
                    Price("A", "C", 4.0),
                    Price("C", "B", 2.0),
                    Price("B", "D", 4.0),
                    Price("D", "F", 2.0),
                ]

                @test min_rate |> conv_value ≈ 8.0
                @test conv_value(min_rate) < conv_value(a_star_rate)
                @test length(conv_chain(a_star_rate)) <= length(conv_chain(min_rate))
                @test min_rate |> conv_chain ==
                      [Price("A", "C", 4.0), Price("C", "E", 2.0), Price("E", "F", 1.0)]
            end

            @testset "Test №2: F -> A" begin
                a_star_rate = conv_a_star(my_graph, "F", "A")
                max_rate = conv_max(my_graph, "F", "A")
                min_rate = conv_min(my_graph, "F", "A")

                @test max_rate |> conv_value ≈ 0.2
                @test conv_value(a_star_rate) < conv_value(max_rate)
                @test length(conv_chain(a_star_rate)) <= length(conv_chain(max_rate))
                @test max_rate |> conv_chain == [
                    Price("E", "F", 1.0),
                    Price("C", "E", 2.0),
                    Price("C", "B", 2.0),
                    Price("A", "B", 5.0),
                ]

                @test min_rate |> conv_value ≈ 0.02
                @test conv_value(min_rate) <= conv_value(a_star_rate)
                @test length(conv_chain(a_star_rate)) <= length(conv_chain(min_rate))
                @test min_rate |> conv_chain == [Price("A", "F", 50.0)]
            end

            @testset "Test №3: A -> B" begin
                a_star_rate = conv_a_star(my_graph, "A", "B")
                max_rate = conv_max(my_graph, "A", "B")
                min_rate = conv_min(my_graph, "A", "B")

                @test max_rate |> conv_value ≈ 50.0
                @test conv_value(a_star_rate) < conv_value(max_rate)
                @test length(conv_chain(a_star_rate)) <= length(conv_chain(max_rate))
                @test max_rate |> conv_chain == [
                    Price("A", "F", 50.0),
                    Price("E", "F", 1.0),
                    Price("C", "E", 2.0),
                    Price("C", "B", 2.0),
                ]

                @test min_rate |> conv_value ≈ 1.0
                @test conv_value(min_rate) < conv_value(a_star_rate)
                @test length(conv_chain(a_star_rate)) <= length(conv_chain(min_rate))
                @test min_rate |> conv_chain == [
                    Price("A", "C", 4.0),
                    Price("C", "E", 2.0),
                    Price("E", "F", 1.0),
                    Price("D", "F", 2.0),
                    Price("B", "D", 4.0),
                ]
            end

            @testset "Test №4: F -> D" begin
                a_star_rate = conv_a_star(my_graph, "F", "D")
                max_rate = conv_max(my_graph, "F", "D")
                min_rate = conv_min(my_graph, "F", "D")

                @test max_rate |> conv_value ≈ 4.0
                @test conv_value(a_star_rate) < conv_value(max_rate)
                @test length(conv_chain(a_star_rate)) <= length(conv_chain(max_rate))
                @test max_rate |> conv_chain == [
                    Price("E", "F", 1.0),
                    Price("C", "E", 2.0),
                    Price("C", "B", 2.0),
                    Price("B", "D", 4.0),
                ]

                @test min_rate |> conv_value ≈ 0.16
                @test conv_value(min_rate) < conv_value(a_star_rate)
                @test length(conv_chain(a_star_rate)) <= length(conv_chain(min_rate))
                @test min_rate |> conv_chain ==
                      [Price("A", "F", 50.0), Price("A", "C", 4.0), Price("C", "D", 2.0)]
            end

            # @testset "Test №5: D -> B" begin
            #     a_star_rate = conv_a_star(my_graph, "D", "B")
            #     max_rate = conv_max(my_graph, "D", "B")
            #     min_rate = conv_min(my_graph, "D", "B")
            #     
            #     @test max_rate |> conv_value ≈ 1.0
            #     @test conv_value(a_star_rate) < conv_value(max_rate)
            #     @test length(conv_chain(a_star_rate)) <= length(conv_chain(max_rate))
            #     @test max_rate |> conv_chain == [
            #         Price("C", "D", 2.0),
            #         Price("C", "B", 2.0),
            #     ]
            #     
            #     @test min_rate |> conv_value ≈ 0.1
            #     @test conv_value(min_rate) < conv_value(a_star_rate)
            #     @test length(conv_chain(a_star_rate)) <= length(conv_chain(min_rate))
            #     @test min_rate |> conv_chain == [
            #         Price("C", "D", 2.0),
            #         Price("C", "E", 2.0),
            #         Price("E", "F", 1.0),
            #         Price("A", "F", 50.0),
            #         Price("A", "B", 5.0),
            #     ]
            # end

            @testset "Test (new) №5: D -> B" begin
                a_star_rate = conv_a_star(my_graph, "D", "B")
                max_rate = conv_max(my_graph, "D", "B")
                min_rate = conv_min(my_graph, "D", "B")

                @test max_rate |> conv_value ≈ 2.0
                @test max_rate |> conv_chain == [
                    Price("D", "F", 2.0),
                    Price("E", "F", 1.0),
                    Price("C", "E", 2.0),
                    Price("C", "B", 2.0),
                ]

                @test min_rate |> conv_value ≈ 0.1
                @test conv_value(min_rate) < conv_value(a_star_rate)
                @test length(conv_chain(a_star_rate)) <= length(conv_chain(min_rate))
                @test min_rate |> conv_chain == [
                    Price("C", "D", 2.0),
                    Price("C", "E", 2.0),
                    Price("E", "F", 1.0),
                    Price("A", "F", 50.0),
                    Price("A", "B", 5.0),
                ]
            end

            @testset "Test №6: A -> Y" begin
                max_rate = conv_max(my_graph, "A", "Y")
                min_rate = conv_min(my_graph, "A", "Y")

                @test max_rate |> conv_value |> isnan
                @test max_rate |> conv_chain |> isempty

                @test min_rate |> conv_value |> isnan
                @test min_rate |> conv_chain |> isempty
            end
        end
    end
end
