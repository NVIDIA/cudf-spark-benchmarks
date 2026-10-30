WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        CONCAT(s.s_address, ', ', n.n_name, ', ', r.r_name) AS full_address,
        p.p_retailprice,
        LENGTH(p.p_comment) AS comment_length,
        REPLACE(REPLACE(p.p_type, ' ', ''), '-', '') AS sanitized_type
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
AggregatedData AS (
    SELECT 
        supplier_name,
        AVG(p_retailprice) AS avg_retail_price,
        SUM(comment_length) AS total_comment_length,
        COUNT(DISTINCT sanitized_type) AS unique_types
    FROM 
        SupplierParts
    GROUP BY 
        supplier_name
)
SELECT 
    supplier_name,
    avg_retail_price,
    total_comment_length,
    unique_types,
    CASE 
        WHEN avg_retail_price > 100 THEN 'High Value Supplier'
        WHEN avg_retail_price BETWEEN 50 AND 100 THEN 'Medium Value Supplier'
        ELSE 'Low Value Supplier' 
    END AS supplier_category
FROM 
    AggregatedData
ORDER BY 
    supplier_name;
