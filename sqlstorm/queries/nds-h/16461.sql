SELECT s_name, SUM(ps_supplycost * ps_availqty) AS total_value
FROM supplier
JOIN partsupp ON supplier.s_suppkey = partsupp.ps_suppkey
GROUP BY s_name
ORDER BY total_value DESC
LIMIT 10;
