WITH StringProcessed AS (
    SELECT 
        p.p_partkey,
        UPPER(p.p_name) AS upper_name,
        LOWER(p.p_comment) AS lower_comment,
        LENGTH(p.p_comment) AS comment_length,
        SUBSTRING(p.p_mfgr FROM 1 FOR 10) AS mfgr_short,
        CONCAT('Brand: ', p.p_brand) AS brand_info,
        REPLACE(p.p_type, 'plastic', 'resin') AS modified_type
    FROM 
        part p
    WHERE 
        p.p_size > 10
),
AggregatedData AS (
    SELECT 
        sp.upper_name,
        sp.lower_comment,
        sp.comment_length,
        sp.mfgr_short,
        sp.brand_info,
        sp.modified_type,
        COUNT(*) AS count_per_type
    FROM 
        StringProcessed sp
    GROUP BY 
        sp.upper_name, 
        sp.lower_comment, 
        sp.comment_length, 
        sp.mfgr_short, 
        sp.brand_info, 
        sp.modified_type
)
SELECT 
    ad.upper_name,
    ad.lower_comment,
    ad.comment_length,
    ad.mfgr_short,
    ad.brand_info,
    ad.modified_type,
    ad.count_per_type
FROM 
    AggregatedData ad
ORDER BY 
    ad.count_per_type DESC, 
    ad.comment_length ASC;
