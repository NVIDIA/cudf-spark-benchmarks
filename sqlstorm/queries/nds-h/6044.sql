
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank,
        n.n_regionkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_supply_cost,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (ORDER BY rs.total_supply_cost DESC) AS overall_rank
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.n_regionkey = n.n_nationkey
    WHERE 
        rs.supplier_rank <= 5
)
SELECT 
    ts.nation_name,
    COUNT(DISTINCT ts.s_suppkey) AS supplier_count,
    AVG(ts.total_supply_cost) AS avg_supply_cost,
    MAX(ts.total_supply_cost) AS max_supply_cost
FROM 
    TopSuppliers ts
GROUP BY 
    ts.nation_name
ORDER BY 
    supplier_count DESC, avg_supply_cost DESC;
