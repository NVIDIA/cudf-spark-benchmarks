WITH  StringProcessing AS (
    SELECT 
        p_partkey, 
        p_name, 
        p_mfgr, 
        p_brand, 
        p_type,
        p_comment,
        LENGTH(p_name) AS name_length,
        LENGTH(p_comment) AS comment_length,
        REPLACE(UPPER(p_name), 'A', '@') AS modified_name,
        REPLACE(LOWER(p_comment), 'IN', 'OUT') AS modified_comment
    FROM 
        part
    WHERE
        p_name LIKE '%part%' 
    UNION ALL
    SELECT 
        ps.ps_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_comment,
        LENGTH(p.p_name) AS name_length,
        LENGTH(ps.ps_comment) AS comment_length,
        REPLACE(UPPER(p.p_name), 'A', '@') AS modified_name,
        REPLACE(LOWER(ps.ps_comment), 'IN', 'OUT') AS modified_comment
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 100
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(sp.name_length) AS avg_name_length,
    AVG(sp.comment_length) AS avg_comment_length,
    STRING_AGG(DISTINCT sp.modified_name, ', ') AS all_modified_names,
    STRING_AGG(DISTINCT sp.modified_comment, ', ') AS all_modified_comments
FROM 
    customer c
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    StringProcessing sp ON sp.p_partkey = o.o_orderkey
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC;
