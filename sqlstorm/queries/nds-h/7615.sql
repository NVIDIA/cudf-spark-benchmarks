WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
TopRegionSuppliers AS (
    SELECT 
        n.n_name AS nation_name,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_suppkey = n.n_nationkey
    WHERE 
        rs.rank <= 5
)
SELECT 
    tr.nation_name,
    COUNT(tr.s_name) AS num_top_suppliers,
    AVG(tr.total_supply_cost) AS avg_supply_cost
FROM 
    TopRegionSuppliers tr
GROUP BY 
    tr.nation_name
ORDER BY 
    num_top_suppliers DESC, avg_supply_cost DESC;
