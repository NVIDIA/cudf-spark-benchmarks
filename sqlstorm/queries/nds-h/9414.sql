
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank,
        n.n_nationkey
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        n.n_name AS nation_name,
        rs.s_name AS supplier_name,
        rs.total_supply_cost
    FROM RankedSuppliers rs
    JOIN nation n ON n.n_nationkey = rs.n_nationkey
    WHERE rs.rank <= 3
)
SELECT 
    ts.nation_name,
    AVG(ts.total_supply_cost) AS avg_total_supply_cost
FROM TopSuppliers ts
GROUP BY ts.nation_name
ORDER BY avg_total_supply_cost DESC
LIMIT 5;
