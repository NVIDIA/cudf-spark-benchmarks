
WITH RankedSuppliers AS (
    SELECT 
        s.s_name AS supplier_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        DENSE_RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
FilteredSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT ns.n_nationkey) AS nations_count,
        SUM(rs.total_cost) AS supplier_cost_sum
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON rs.supplier_name = s.s_name 
    JOIN 
        nation ns ON s.s_nationkey = ns.n_nationkey 
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 5
    GROUP BY 
        r.r_name
)
SELECT 
    region_name,
    nations_count,
    CONCAT('Total Cost: $', CAST(ROUND(supplier_cost_sum, 2) AS STRING)) AS formatted_cost
FROM 
    FilteredSuppliers
ORDER BY 
    supplier_cost_sum DESC;
