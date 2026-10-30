WITH ConcatenatedData AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name,
        CONCAT(p.p_name, ' from ', s.s_name) AS product_supplier,
        LENGTH(CONCAT(p.p_name, ' from ', s.s_name)) AS combined_length
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
GroupedData AS (
    SELECT 
        p_partkey,
        COUNT(s_name) AS supplier_count,
        SUM(combined_length) AS total_length
    FROM 
        ConcatenatedData
    GROUP BY 
        p_partkey
)
SELECT 
    r.r_name,
    SUM(g.total_length) AS region_total_length,
    MAX(g.supplier_count) AS max_suppliers
FROM 
    GroupedData g
JOIN 
    supplier s ON g.p_partkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE 'S%'
GROUP BY 
    r.r_name
ORDER BY 
    region_total_length DESC;
