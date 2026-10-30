SELECT s.s_name, p.p_name, ps.ps_supplycost
FROM supplier s
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
WHERE ps.ps_availqty > 100
ORDER BY ps.ps_supplycost DESC;
