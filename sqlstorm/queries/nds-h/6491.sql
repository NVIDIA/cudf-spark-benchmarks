WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_cost DESC
    LIMIT 10
),
TotalVolume AS (
    SELECT l.l_partkey, SUM(l.l_quantity) AS total_quantity
    FROM lineitem l
    WHERE l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY l.l_partkey
),
PartCost AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_container, pv.total_quantity * ps.ps_supplycost AS estimated_cost
    FROM part p
    JOIN TotalVolume pv ON p.p_partkey = pv.l_partkey
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_suppkey IN (SELECT s_suppkey FROM RankedSuppliers)
)
SELECT r.r_name, COUNT(DISTINCT c.c_custkey) AS customer_count, SUM(pc.estimated_cost) AS total_estimated_cost
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN customer c ON s.s_suppkey = c.c_nationkey
JOIN PartCost pc ON pc.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O'))
GROUP BY r.r_name
ORDER BY total_estimated_cost DESC;