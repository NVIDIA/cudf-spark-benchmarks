WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_acctbal,
        LENGTH(s.s_comment) AS comment_length,
        REPLACE(s.s_comment, 'dummy', 'replacement') AS modified_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),

PartInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_type,
        p.p_size,
        p.p_container,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment,
        CONCAT(p.p_name, ' - ', p.p_brand) AS full_description
    FROM 
        part p
)

SELECT 
    si.s_name,
    si.nation_name,
    si.region_name,
    pi.p_name,
    pi.full_description,
    pi.short_comment,
    si.modified_comment,
    pi.p_size,
    si.s_acctbal,
    si.comment_length
FROM 
    SupplierInfo si
JOIN 
    partsupp ps ON si.s_suppkey = ps.ps_suppkey
JOIN 
    PartInfo pi ON ps.ps_partkey = pi.p_partkey
WHERE 
    UPPER(si.nation_name) LIKE '%USA%' 
    AND pi.p_type IN ('Hardware', 'Software')
ORDER BY 
    si.s_acctbal DESC, pi.p_name;
