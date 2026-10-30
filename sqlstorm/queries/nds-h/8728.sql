WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
MaxRegionSuppliers AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        ARRAY_AGG(s.s_name) AS top_suppliers
    FROM 
        region r
    JOIN 
        RankedSuppliers s ON s.supplier_rank = 1
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    r.r_name AS region_name,
    ms.top_suppliers
FROM 
    MaxRegionSuppliers ms
JOIN 
    region r ON ms.r_regionkey = r.r_regionkey
WHERE 
    ms.top_suppliers IS NOT NULL
ORDER BY 
    r.r_name;
