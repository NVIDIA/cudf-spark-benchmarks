SELECT s_name, SUM(ps_supplycost * ps_availqty) AS total_cost
FROM supplier
JOIN partsupp ON s_suppkey = ps_suppkey
GROUP BY s_name
ORDER BY total_cost DESC
LIMIT 10;
