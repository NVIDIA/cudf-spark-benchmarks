WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
), RegionNation AS (
    SELECT r.r_regionkey, r.r_name, n.n_nationkey, n.n_name
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
), SupplierRanking AS (
    SELECT ns.n_nationkey, ns.n_name, SUM(rs.total_supply_cost) AS total_cost
    FROM RankedSuppliers rs
    JOIN RegionNation ns ON rs.s_nationkey = ns.n_nationkey
    GROUP BY ns.n_nationkey, ns.n_name
    ORDER BY total_cost DESC
)
SELECT cr.c_custkey, cr.c_name, sr.n_name AS supplier_nation, cr.total_orders, cr.total_spent, sr.total_cost
FROM CustomerOrders cr
JOIN SupplierRanking sr ON cr.c_nationkey = sr.n_nationkey
WHERE cr.total_orders > 5 AND sr.total_cost > 100000
ORDER BY cr.total_spent DESC, sr.total_cost DESC
LIMIT 10;
