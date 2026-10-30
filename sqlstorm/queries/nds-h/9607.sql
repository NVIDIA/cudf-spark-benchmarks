WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.nation_name,
        rs.total_supply_cost
    FROM RankedSuppliers rs
    WHERE rs.rnk <= 5
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    ts.s_name,
    ts.total_supply_cost
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
WHERE p.p_retailprice > 100.00
ORDER BY ts.total_supply_cost DESC, p.p_name;
