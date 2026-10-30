SELECT p.p_name, s.s_name, ps.ps_supplycost
FROM partsupp ps
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE ps.ps_availqty > 100
ORDER BY ps.ps_supplycost DESC;
