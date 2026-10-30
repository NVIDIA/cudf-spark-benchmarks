WITH StringOperations AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        CONCAT(p.p_name, ' - ', p.p_brand, ' ', p.p_type) AS full_description,
        LENGTH(CONCAT(p.p_name, ' - ', p.p_brand, ' ', p.p_type)) AS description_length,
        REPLACE(p.p_comment, 'Soft', 'Hard') AS modified_comment
    FROM 
        part p
),
AggregatedData AS (
    SELECT 
        COUNT(*) AS total_parts,
        AVG(description_length) AS average_description_length,
        COUNT(CASE WHEN LENGTH(modified_comment) > 20 THEN 1 END) AS long_comments
    FROM 
        StringOperations
)
SELECT 
    ad.total_parts, 
    ad.average_description_length, 
    ad.long_comments,
    rn.r_name AS region_name,
    COUNT(DISTINCT s.s_suppkey) AS total_suppliers
FROM 
    AggregatedData ad
JOIN 
    supplier s ON s.s_acctbal > 1000
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region rn ON n.n_regionkey = rn.r_regionkey
GROUP BY 
    rn.r_name, ad.total_parts, ad.average_description_length, ad.long_comments
ORDER BY 
    ad.total_parts DESC, average_description_length DESC;
