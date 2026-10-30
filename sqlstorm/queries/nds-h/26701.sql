
WITH StringBenchmark AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        CONCAT(UPPER(p.p_name), ' - ', LEFT(p.p_comment, 10)) AS processed_name,
        LENGTH(SUBSTRING(p.p_mfgr, 1, 10)) AS mfgr_length,
        REPLACE(p.p_brand, 'Brand', 'NewBrand') AS modified_brand,
        CHAR_LENGTH(p.p_type) AS type_length,
        TRIM(REPLACE(p.p_container, 'Container', 'Box')) AS trimmed_container,
        SUBSTRING(UPPER(p.p_comment), 1, 20) AS shortened_comment
    FROM 
        part p
),
AggregatedData AS (
    SELECT 
        COUNT(DISTINCT processed_name) AS unique_processed_names,
        AVG(mfgr_length) AS avg_mfgr_length,
        COUNT(DISTINCT modified_brand) AS unique_brands,
        SUM(type_length) AS total_type_length,
        COUNT(trimmed_container) AS total_trimmed_containers,
        MAX(shortened_comment) AS longest_comment
    FROM 
        StringBenchmark
    GROUP BY
        processed_name
)
SELECT 
    a.unique_processed_names, 
    a.avg_mfgr_length, 
    a.unique_brands, 
    a.total_type_length, 
    a.total_trimmed_containers, 
    a.longest_comment,
    r.r_name AS region_name
FROM 
    AggregatedData a
JOIN 
    nation n ON n.n_nationkey = (SELECT MAX(n_nationkey) FROM nation)
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
WHERE 
    a.unique_processed_names > 0;
