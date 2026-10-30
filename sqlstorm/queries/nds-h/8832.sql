WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
    ORDER BY total_supply_cost DESC
), 
HighCostSuppliers AS (
    SELECT rs.s_suppkey, rs.s_name, r.r_name, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM RankedSuppliers rs
    JOIN nation n ON rs.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN lineitem l ON l.l_suppkey = rs.s_suppkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE rs.total_supply_cost > (SELECT AVG(total_supply_cost) FROM RankedSuppliers)
    GROUP BY rs.s_suppkey, rs.s_name, r.r_name
), 
OrdersSummary AS (
    SELECT hs.s_suppkey, hs.s_name, hs.r_name, SUM(o.o_totalprice) AS total_order_value
    FROM HighCostSuppliers hs
    JOIN lineitem l ON hs.s_suppkey = l.l_suppkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY hs.s_suppkey, hs.s_name, hs.r_name
)
SELECT hs.s_name, hs.r_name, os.total_order_value, COUNT(DISTINCT l.l_orderkey) AS total_orders
FROM HighCostSuppliers hs
JOIN OrdersSummary os ON hs.s_suppkey = os.s_suppkey
JOIN lineitem l ON hs.s_suppkey = l.l_suppkey
WHERE os.total_order_value > 50000
GROUP BY hs.s_name, hs.r_name, os.total_order_value
ORDER BY total_orders DESC, os.total_order_value DESC;
