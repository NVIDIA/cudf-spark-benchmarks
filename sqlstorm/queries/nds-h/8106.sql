
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_by_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_nationkey
), 
TopSuppliers AS (
    SELECT 
        rs.nation_name,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank_by_cost <= 3
)
SELECT 
    t.nation_name,
    COUNT(*) AS num_top_suppliers,
    AVG(t.total_supply_cost) AS avg_supply_cost
FROM 
    TopSuppliers t
GROUP BY 
    t.nation_name
ORDER BY 
    num_top_suppliers DESC, avg_supply_cost DESC;
