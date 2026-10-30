
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(p.ps_suppkey) AS total_parts,
        RANK() OVER (PARTITION BY n.n_name ORDER BY COUNT(p.ps_suppkey) DESC) AS rank_within_nation,
        n.n_name,
        s.s_nationkey
    FROM 
        supplier s
    JOIN 
        partsupp p ON s.s_suppkey = p.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region,
        rs.s_name,
        rs.total_parts
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank_within_nation <= 5
)
SELECT 
    rs.region,
    COUNT(rs.s_name) AS top_supplier_count,
    AVG(rs.total_parts) AS avg_parts_per_supplier
FROM 
    TopSuppliers rs
GROUP BY 
    rs.region
ORDER BY 
    top_supplier_count DESC;
