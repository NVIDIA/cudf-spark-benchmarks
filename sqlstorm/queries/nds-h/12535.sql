SELECT s_name, SUM(ps_supplycost * ps_availqty) AS total_cost
FROM supplier
JOIN partsupp ON s_suppkey = ps_suppkey
JOIN part ON ps_partkey = p_partkey
GROUP BY s_name
ORDER BY total_cost DESC
LIMIT 10;