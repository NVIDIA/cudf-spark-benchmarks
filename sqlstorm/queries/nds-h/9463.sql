
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank,
        n.n_nationkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey
)
SELECT 
    r.r_name AS region, 
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count, 
    AVG(rs.total_supply_cost) AS avg_supply_cost
FROM 
    RankedSuppliers rs
JOIN 
    nation n ON rs.n_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    rs.rank <= 3
GROUP BY 
    r.r_name
ORDER BY 
    supplier_count DESC, avg_supply_cost DESC;
