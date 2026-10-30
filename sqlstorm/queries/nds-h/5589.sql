WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
NationInfo AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    si.s_name AS supplier_name,
    ni.n_name AS nation_name,
    ni.region_name,
    SUM(co.total_spent) AS total_revenue,
    AVG(si.total_supply_cost) AS avg_supply_cost
FROM SupplierInfo si
JOIN NationInfo ni ON si.s_nationkey = ni.n_nationkey
LEFT JOIN CustomerOrderStats co ON si.s_suppkey = co.c_custkey
WHERE ni.region_name = 'ASIA'
GROUP BY si.s_name, ni.n_name, ni.region_name
ORDER BY total_revenue DESC, avg_supply_cost ASC
LIMIT 10;
