WITH processed_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        upper(p.p_name) AS upper_name,
        lower(p.p_comment) AS lower_comment,
        length(p.p_comment) AS comment_length,
        concat(p.p_mfgr, ' - ', p.p_brand) AS mfgr_brand,
        replace(p.p_container, 'box', 'container') AS container_type
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 50
),
supplier_analysis AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        substring(s.s_comment from 1 for 50) AS short_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 1000.00
)
SELECT 
    pp.p_partkey,
    pp.upper_name,
    pp.lower_comment,
    pp.comment_length,
    pp.mfgr_brand,
    pp.container_type,
    sa.s_name AS supplier_name,
    sa.nation,
    sa.short_comment
FROM 
    processed_parts pp
JOIN 
    partsupp ps ON pp.p_partkey = ps.ps_partkey
JOIN 
    supplier_analysis sa ON ps.ps_suppkey = sa.s_suppkey
WHERE 
    pp.comment_length > 10
ORDER BY 
    pp.comment_length DESC, pp.upper_name;
