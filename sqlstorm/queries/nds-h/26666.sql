WITH RankedSuppliers AS (
    SELECT 
        s.s_name, 
        s.s_nationkey, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        rt.s_name,
        r.r_name,
        rt.part_count
    FROM 
        RankedSuppliers rt
    JOIN 
        nation n ON rt.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rt.rank <= 3
)
SELECT 
    CONCAT('Supplier: ', ts.s_name, ' | Region: ', ts.r_name, ' | Parts Supplied: ', ts.part_count) AS supplier_info
FROM 
    TopSuppliers ts
ORDER BY 
    ts.r_name, ts.part_count DESC;
