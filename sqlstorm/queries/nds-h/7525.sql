WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        rs.nation_name,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 5
)
SELECT 
    region.r_name,
    COUNT(DISTINCT ts.s_name) AS top_supplier_count,
    AVG(ts.total_supply_cost) AS avg_top_supplier_cost
FROM 
    region
LEFT JOIN 
    nation n ON region.r_regionkey = n.n_regionkey
LEFT JOIN 
    TopSuppliers ts ON n.n_name = ts.nation_name
GROUP BY 
    region.r_name
ORDER BY 
    top_supplier_count DESC, avg_top_supplier_cost DESC
LIMIT 10;
