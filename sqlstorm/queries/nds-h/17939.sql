SELECT DISTINCT p.p_name, s.s_name
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE p.p_retailprice > 100.00
ORDER BY p.p_name;
