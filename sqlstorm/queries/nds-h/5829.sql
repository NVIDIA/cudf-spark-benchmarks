
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_nationkey, n.n_name
),
TopSuppliers AS (
    SELECT 
        nation_name,
        s_name,
        total_supply_cost
    FROM RankedSuppliers rs
    WHERE rs.rank <= 3
)
SELECT 
    r.r_name AS region,
    ts.nation_name,
    COUNT(DISTINCT ts.s_name) AS top_supplier_count,
    SUM(ts.total_supply_cost) AS total_top_supply_cost
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN TopSuppliers ts ON n.n_name = ts.nation_name
GROUP BY r.r_name, ts.nation_name
ORDER BY total_top_supply_cost DESC;
