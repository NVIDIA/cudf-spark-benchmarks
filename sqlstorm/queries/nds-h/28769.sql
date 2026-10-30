WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
SupplierStrings AS (
    SELECT 
        s.s_suppkey,
        CONCAT(s.s_name, ' - ', r.r_name) AS supplier_region,
        UPPER(SUBSTRING(s.s_name FROM 1 FOR 3)) AS name_prefix
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    ss.supplier_region,
    ss.name_prefix,
    rs.total_value
FROM 
    SupplierStrings ss
JOIN 
    RankedSuppliers rs ON ss.s_suppkey = rs.s_suppkey
WHERE 
    rs.rank <= 3
ORDER BY 
    rs.total_value DESC;
