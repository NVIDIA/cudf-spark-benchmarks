SELECT s_suppkey, s_name, SUM(ps_supplycost * ps_availqty) AS total_value
FROM supplier s
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
GROUP BY s_suppkey, s_name
ORDER BY total_value DESC
LIMIT 10;
