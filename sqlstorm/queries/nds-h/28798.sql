WITH StringProcessing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_comment,
        CONCAT('Brand: ', p.p_brand, '; Name: ', p.p_name, '; Comment: ', p.p_comment) AS detailed_info,
        LENGTH(CONCAT('Brand: ', p.p_brand, '; Name: ', p.p_name, '; Comment: ', p.p_comment)) AS string_length,
        LOWER(p.p_name) AS lower_name,
        UPPER(p.p_name) AS upper_name,
        REPLACE(p.p_comment, ' ', '-') AS modified_comment
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT s.s_suppkey FROM supplier s WHERE s.s_acctbal > 1000)
),
RankedStrings AS (
    SELECT 
        detailed_info,
        string_length,
        ROW_NUMBER() OVER (ORDER BY string_length DESC) AS rank
    FROM 
        StringProcessing
)
SELECT 
    ranked.detailed_info,
    ranked.string_length,
    r.r_name AS region_name
FROM 
    RankedStrings ranked
JOIN 
    nation n ON ranked.rank % 25 = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    ranked.string_length > 100;
