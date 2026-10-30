WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT s.s_nationkey, RANK() OVER (PARTITION BY s.s_nationkey ORDER BY total_supply_cost DESC) AS rnk
    FROM RankedSuppliers s
)
SELECT n.n_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_inventory_value, COUNT(DISTINCT s.s_suppkey) AS supplier_count
FROM nation n
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN TopSuppliers ts ON s.s_nationkey = ts.s_nationkey
WHERE ts.rnk <= 5
GROUP BY n.n_name
ORDER BY total_inventory_value DESC;
