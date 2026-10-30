WITH ranked_suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
high_value_parts AS (
    SELECT p.p_partkey, p.p_name, AVG(l.l_extendedprice) AS avg_extended_price
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate >= '1997-01-01' AND l.l_shipdate <= '1997-12-31'
    GROUP BY p.p_partkey, p.p_name
    HAVING AVG(l.l_extendedprice) > 100.00
),
top_nations AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name
    ORDER BY customer_count DESC
    LIMIT 5
)
SELECT r.r_name AS region_name, 
       tn.n_name AS nation_name, 
       ts.s_name AS supplier_name, 
       hp.p_name AS part_name, 
       hp.avg_extended_price, 
       ts.total_supply_cost
FROM region r
JOIN nation tn ON r.r_regionkey = tn.n_regionkey
JOIN ranked_suppliers ts ON tn.n_nationkey = ts.s_suppkey
JOIN high_value_parts hp ON ts.s_suppkey = hp.p_partkey
WHERE ts.total_supply_cost > 50000
ORDER BY r.r_name, tn.n_name, ts.total_supply_cost DESC;