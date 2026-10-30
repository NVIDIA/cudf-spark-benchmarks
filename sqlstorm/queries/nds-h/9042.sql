WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), TopSuppliers AS (
    SELECT rs.*, RANK() OVER (ORDER BY rs.total_supply_value DESC) AS rnk
    FROM RankedSuppliers rs
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
), SupplierRegions AS (
    SELECT ns.n_nationkey, r.r_regionkey, r.r_name, SUM(ts.total_supply_value) AS region_supply_value
    FROM TopSuppliers ts
    JOIN nation ns ON ts.s_nationkey = ns.n_nationkey
    JOIN region r ON ns.n_regionkey = r.r_regionkey
    GROUP BY ns.n_nationkey, r.r_regionkey, r.r_name
)
SELECT cr.c_name, cr.total_spent, sr.r_name, sr.region_supply_value
FROM CustomerOrders cr
JOIN SupplierRegions sr ON cr.c_nationkey = sr.n_nationkey
WHERE cr.order_count > 10
ORDER BY cr.total_spent DESC, sr.region_supply_value ASC
LIMIT 50;
