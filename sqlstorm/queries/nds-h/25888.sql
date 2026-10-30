
WITH  StringBenchmarks AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_comment,
        LENGTH(p.p_name) AS name_length,
        LENGTH(p.p_comment) AS comment_length,
        SUBSTRING(p.p_name, 1, 5) AS name_substr,
        UPPER(p.p_brand) AS brand_upper,
        LOWER(p.p_comment) AS comment_lower,
        CONCAT(p.p_name, ' - ', p.p_brand) AS name_brand_concat
    FROM 
        part p
), 
RegionNation AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        STRING_AGG(sb.name_brand_concat, '; ') AS combined_strings
    FROM 
        StringBenchmarks sb
    JOIN 
        supplier s ON s.s_suppkey = sb.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    rn.nation_name,
    rn.region_name,
    rn.combined_strings,
    COUNT(rn.combined_strings) AS total_entries,
    AVG(sb.name_length) AS avg_name_length,
    AVG(sb.comment_length) AS avg_comment_length
FROM 
    RegionNation rn
JOIN 
    StringBenchmarks sb ON POSITION(sb.name_substr IN rn.combined_strings) > 0
GROUP BY 
    rn.nation_name, rn.region_name, rn.combined_strings
ORDER BY 
    total_entries DESC, rn.nation_name, rn.region_name;
