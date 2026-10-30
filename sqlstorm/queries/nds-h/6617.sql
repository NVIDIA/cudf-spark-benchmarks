WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
SelectedRegions AS (
    SELECT r.r_regionkey
    FROM region r
    WHERE r.r_name IN ('ASIA', 'EUROPE')
),
NationDetails AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey
    FROM nation n
    JOIN SelectedRegions r ON n.n_regionkey = r.r_regionkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, SUM(o.o_totalprice) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
)
SELECT ns.n_name, COUNT(DISTINCT co.c_custkey) AS customer_count, SUM(rs.total_cost) AS total_supplier_cost
FROM NationDetails ns
JOIN CustomerOrders co ON ns.n_nationkey = co.c_nationkey
JOIN RankedSuppliers rs ON ns.n_nationkey = rs.s_nationkey
GROUP BY ns.n_name
ORDER BY total_supplier_cost DESC, customer_count DESC
LIMIT 10;
