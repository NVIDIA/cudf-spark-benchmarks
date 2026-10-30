WITH StringAggregation AS (
    SELECT 
        p.p_partkey,
        CONCAT_WS(' ', p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_container) AS full_description,
        LENGTH(CONCAT_WS(' ', p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_container)) AS description_length,
        r.r_name AS region_name,
        n.n_name AS nation_name,
        s.s_name AS supplier_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    region_name,
    nation_name,
    COUNT(*) AS total_parts,
    AVG(description_length) AS avg_description_length,
    MIN(description_length) AS min_description_length,
    MAX(description_length) AS max_description_length
FROM 
    StringAggregation
GROUP BY 
    region_name, nation_name
ORDER BY 
    region_name, nation_name;
