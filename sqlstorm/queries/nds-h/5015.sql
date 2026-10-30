WITH RegionalSuppliers AS (
    SELECT n.n_name AS nation_name, r.r_name AS region_name, s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name, r.r_name, s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT nation_name, region_name, s_suppkey, s_name, total_supply_cost
    FROM RegionalSuppliers
    WHERE total_supply_cost > (
        SELECT AVG(total_supply_cost) FROM RegionalSuppliers
    )
)
SELECT h.nation_name, h.region_name, h.s_name, COUNT(DISTINCT o.o_orderkey) AS order_count, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM HighValueSuppliers h
JOIN lineitem l ON h.s_suppkey = l.l_suppkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
WHERE o.o_orderstatus = 'O'
GROUP BY h.nation_name, h.region_name, h.s_name
ORDER BY total_revenue DESC
LIMIT 10;
