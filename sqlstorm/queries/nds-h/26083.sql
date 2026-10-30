WITH StringProcessing AS (
    SELECT 
        p.p_name,
        CONCAT('Part Name: ', p.p_name, ' | Retail Price: ', CAST(p.p_retailprice AS CHAR(10)), ' | Comment: ', p.p_comment) AS detailed_info,
        LENGTH(p.p_name) AS name_length,
        UPPER(p.p_comment) AS upper_comment,
        LOWER(p.p_mfgr) AS lower_mfgr,
        REPLACE(p.p_type, ' ', '_') AS type_with_underscores
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
RankedParts AS (
    SELECT 
        sp.detailed_info,
        RANK() OVER (ORDER BY sp.name_length DESC) AS name_rank
    FROM 
        StringProcessing sp
)
SELECT 
    rp.detailed_info,
    rp.name_rank
FROM 
    RankedParts rp
WHERE 
    rp.name_rank <= 10
ORDER BY 
    rp.name_rank;
