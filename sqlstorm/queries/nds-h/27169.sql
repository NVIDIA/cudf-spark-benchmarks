WITH processed_data AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        n.n_name AS nation_name,
        SUBSTRING(p.p_comment, 1, 20) AS short_comment,
        CONCAT('Supplier ', s.s_name, ' from ', n.n_name) AS supplier_info,
        REPLACE(LOWER(p.p_type), ' ', '-') AS modified_type,
        LENGTH(s.s_comment) AS comment_length
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        p.p_retailprice > 100.00
),
aggregated_data AS (
    SELECT 
        modified_type,
        COUNT(*) AS total_parts,
        AVG(comment_length) AS avg_comment_length
    FROM 
        processed_data
    GROUP BY 
        modified_type
)
SELECT 
    ad.modified_type,
    ad.total_parts,
    ad.avg_comment_length,
    pd.supplier_info
FROM 
    aggregated_data ad
JOIN 
    processed_data pd ON ad.modified_type = pd.modified_type
ORDER BY 
    ad.total_parts DESC, 
    ad.avg_comment_length ASC;
