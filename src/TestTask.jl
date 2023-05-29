module TestTask

module NaiveMon

using Lazy: @>>
using HTTP
using TypeClasses

test_sem = Base.Semaphore(1)

dl(url::String) = begin
  @async @Try begin 
    if test_sem.curr_cnt == 0 Base.acquire(test_sem) end 
    HTTP.request("GET", url)
  end
end

dl(urls) = map(dl, urls) 

collect_errors(fs::Vector{Task}) = begin
  split_errs(results) = (filter(x->x isa HTTP.Response, results),
                         filter(x->x isa Const        , results))
  unpack(t::Task) = @>> t  fetch  flatmap(identity)
  #Base.release(test_sem)
  @async split_errs(map(unpack,fs))
end

await(ts) = (args) -> fetch(ts(args))

end #module NaiveMon


module Effs

using TypeClasses
using ExtensibleEffects
using HTTP 

test_sem = Base.Semaphore(1)

dl(urls) = @syntax_eff noautorun(Task) begin
  u = urls
  #@pure Base.acquire(test_sem)
  r = @async @Try begin 
    if test_sem.curr_cnt == 0 Base.acquire(test_sem) end
    HTTP.request("GET", u)
  end
end

collect_errors(tasks) = begin  
  res = @syntax_eff begin
    f = tasks
    @pure r = f
    x = r
    @pure x isa Identity ? ([x],[]) : ([],[x])
  end
  #Base.release(test_sem)
  reduce(⊕, res)
end

await(f) = args -> f(args)

end #module Effs


using Test

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

end # module TestTask
