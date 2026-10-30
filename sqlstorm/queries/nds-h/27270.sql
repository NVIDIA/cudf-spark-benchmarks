WITH StringMetrics AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        LENGTH(p.p_name) AS name_length,
        UPPER(p.p_name) AS upper_name,
        LOWER(p.p_comment) AS lower_comment,
        CONCAT_WS('-', p.p_mfgr, p.p_brand, p.p_type) AS full_description,
        REGEXP_REPLACE(p.p_comment, '[^a-zA-Z0-9 ]', '') AS sanitized_comment
    FROM 
        part p
    WHERE 
        p.p_size > 10
), 
NationCounts AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    sm.p_partkey, 
    sm.name_length, 
    sm.upper_name, 
    sm.lower_comment, 
    sm.full_description, 
    sm.sanitized_comment, 
    nc.n_name AS supplier_nation,
    nc.supplier_count
FROM 
    StringMetrics sm
JOIN 
    NationCounts nc ON sm.p_partkey % nc.supplier_count = 0
ORDER BY 
    sm.name_length DESC, nc.supplier_count ASC
LIMIT 100;
