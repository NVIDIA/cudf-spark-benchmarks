
WITH StringAnalysis AS (
    SELECT 
        p.p_partkey,
        LENGTH(p.p_name) AS name_length,
        REGEXP_REPLACE(p.p_comment, '[^A-Za-z0-9]', '') AS sanitized_comment,
        SUBSTR(p.p_mfgr, 1, 5) AS mfgr_prefix,
        CONCAT(p.p_brand, ' - ', p.p_type) AS brand_type_combination,
        REPLACE(p.p_container, 'Box', 'Container') AS container_type
    FROM part p
),
AggregatedData AS (
    SELECT 
        COUNT(p_partkey) AS part_count,
        AVG(name_length) AS avg_name_length,
        MAX(LENGTH(sanitized_comment)) AS max_sanitized_comment_length,
        MIN(mfgr_prefix) AS min_mfgr_prefix,
        COUNT(DISTINCT brand_type_combination) AS unique_brand_types,
        COUNT(DISTINCT container_type) AS unique_containers
    FROM StringAnalysis
)
SELECT 
    a.part_count,
    a.avg_name_length,
    a.max_sanitized_comment_length,
    a.min_mfgr_prefix,
    a.unique_brand_types,
    a.unique_containers,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count
FROM AggregatedData a
JOIN supplier s ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
JOIN region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = 'USA')
JOIN nation n ON n.n_nationkey = s.s_nationkey
GROUP BY 
    a.part_count, 
    a.avg_name_length, 
    a.max_sanitized_comment_length, 
    a.min_mfgr_prefix, 
    a.unique_brand_types, 
    a.unique_containers, 
    r.r_name, 
    n.n_name
HAVING a.part_count > 100;
