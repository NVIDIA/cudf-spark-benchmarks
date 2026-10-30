
WITH  string_processing_benchmark AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        LENGTH(s.s_name) AS name_length,
        SUBSTRING(s.s_name FROM 1 FOR 5) AS name_prefix,
        UPPER(s.s_name) AS name_uppercase,
        LOWER(s.s_name) AS name_lowercase,
        TRIM(s.s_comment) AS trimmed_comment,
        REPLACE(s.s_comment, 'supply', 'supplying') AS modified_comment
    FROM 
        supplier s
    WHERE 
        s.s_name LIKE '%Corp%'
),
unique_name_counts AS (
    SELECT 
        name_prefix,
        COUNT(DISTINCT s_suppkey) AS unique_supplier_count
    FROM 
        string_processing_benchmark
    GROUP BY 
        name_prefix
),
region_supplier_info AS (
    SELECT 
        r.r_name AS region_name,
        us.unique_supplier_count,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        unique_name_counts us ON SUBSTRING(s.s_name FROM 1 FOR 5) = us.name_prefix
    GROUP BY 
        r.r_name, us.unique_supplier_count
)
SELECT 
    region_name,
    unique_supplier_count,
    total_suppliers,
    ROUND((CAST(unique_supplier_count AS decimal) / NULLIF(total_suppliers, 0)) * 100, 2) AS unique_supplier_percentage
FROM 
    region_supplier_info
ORDER BY 
    unique_supplier_percentage DESC;
