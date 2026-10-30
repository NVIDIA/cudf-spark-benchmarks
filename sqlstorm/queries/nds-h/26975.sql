WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        SUBSTRING(s.s_comment, 1, 30) AS short_comment,
        LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        CONCAT(p.p_name, ' - ', p.p_brand) AS part_description,
        p.p_retailprice
    FROM 
        part p
    WHERE 
        p.p_size > 10
),
Combined AS (
    SELECT 
        pd.part_description,
        sd.s_name,
        sd.short_comment,
        sd.comment_length,
        COUNT(*) AS supply_count
    FROM 
        PartDetails pd
    JOIN 
        partsupp ps ON pd.p_partkey = ps.ps_partkey
    JOIN 
        SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
    GROUP BY 
        pd.part_description, sd.s_name, sd.short_comment, sd.comment_length
)
SELECT 
    part_description, 
    s_name, 
    supply_count,
    CASE 
        WHEN supply_count > 10 THEN 'High Supply'
        ELSE 'Low Supply'
    END AS supply_status
FROM 
    Combined
WHERE 
    short_comment LIKE '%urgent%'
ORDER BY 
    supply_count DESC, part_description;
