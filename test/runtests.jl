using Test
using TestTask: NaiveMon, Effs

@testset "TypeClasses" begin
  urls = [raw"https://google.com", raw"https://httpbin.org", raw"https://ya.ru"]
  @test NaiveMon.test_sem.curr_cnt == 0
  comp = NaiveMon.collect_errors ∘ NaiveMon.dl
  @test NaiveMon.test_sem.curr_cnt == 0
  res, err = NaiveMon.await(comp)(urls)
  @test NaiveMon.test_sem.curr_cnt == 1
end

@testset "ExtensibleEffects" begin
  urls = [raw"https://google.com", raw"https://httpbin.org", raw"https://ya.ru"]
  @test Effs.test_sem.curr_cnt == 0
  comp = Effs.collect_errors ∘ Effs.dl
  @test Effs.test_sem.curr_cnt == 0
  Effs.await(comp)(urls)
  @test Effs.test_sem.curr_cnt == 1
end