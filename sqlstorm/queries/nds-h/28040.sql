WITH StringMetrics AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_container,
        LENGTH(p.p_name) AS name_length,
        LENGTH(p.p_mfgr) AS mfgr_length,
        LENGTH(p.p_brand) AS brand_length,
        LENGTH(p.p_type) AS type_length,
        LENGTH(p.p_container) AS container_length,
        CONCAT(p.p_name, ' ', p.p_brand, ' ', p.p_mfgr) AS full_description,
        UPPER(p.p_comment) AS upper_comment,
        LOWER(p.p_comment) AS lower_comment,
        LENGTH(REPLACE(p.p_comment, ' ', '')) AS char_count_without_spaces
    FROM part p
),
AggregatedMetrics AS (
    SELECT 
        AVG(name_length) AS avg_name_length,
        MAX(name_length) AS max_name_length,
        MIN(name_length) AS min_name_length,
        AVG(mfgr_length) AS avg_mfgr_length,
        MAX(mfgr_length) AS max_mfgr_length,
        MIN(mfgr_length) AS min_mfgr_length,
        AVG(brand_length) AS avg_brand_length,
        MAX(brand_length) AS max_brand_length,
        MIN(brand_length) AS min_brand_length,
        COUNT(DISTINCT p_partkey) AS total_parts,
        SUM(char_count_without_spaces) AS total_characters_without_spaces
    FROM StringMetrics
)
SELECT 
    a.avg_name_length, 
    a.max_name_length, 
    a.min_name_length, 
    a.avg_mfgr_length, 
    a.max_mfgr_length, 
    a.min_mfgr_length, 
    a.avg_brand_length, 
    a.max_brand_length, 
    a.min_brand_length, 
    a.total_parts, 
    a.total_characters_without_spaces
FROM AggregatedMetrics a;
