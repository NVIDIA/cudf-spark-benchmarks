WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopRegions AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_name
    HAVING 
        COUNT(DISTINCT n.n_nationkey) > 3
)
SELECT 
    r.r_name AS region_name,
    ts.s_name AS top_supplier,
    ts.total_cost,
    ts.supplier_nation
FROM 
    RankedSuppliers ts
JOIN 
    TopRegions r ON ts.supplier_nation = r.r_name
WHERE 
    ts.rank = 1
ORDER BY 
    r.r_name, ts.total_cost DESC
LIMIT 10;
