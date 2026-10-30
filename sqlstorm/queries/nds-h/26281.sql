
WITH string_metrics AS (
    SELECT 
        p.p_partkey,
        LENGTH(p.p_name) AS name_length,
        LENGTH(p.p_mfgr) AS mfgr_length,
        LENGTH(p.p_brand) AS brand_length,
        LENGTH(p.p_type) AS type_length,
        LENGTH(p.p_container) AS container_length,
        LENGTH(p.p_comment) AS comment_length,
        p.p_retailprice,
        SUM(CASE WHEN ps.ps_partkey IS NOT NULL THEN ps.ps_availqty ELSE 0 END) AS total_avail_qty
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, 
        p.p_retailprice, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_container, 
        p.p_comment
),
comment_stats AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT c.c_custkey) AS unique_customers,
        SUM(LENGTH(c.c_comment)) AS total_comment_length
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    sm.p_partkey,
    sm.name_length,
    sm.mfgr_length,
    sm.brand_length,
    sm.type_length,
    sm.container_length,
    sm.comment_length,
    sm.p_retailprice,
    cm.nation_name,
    cm.unique_customers,
    cm.total_comment_length,
    sm.total_avail_qty
FROM 
    string_metrics sm
JOIN 
    comment_stats cm ON MOD(sm.p_partkey, 10) = MOD(cm.unique_customers, 10)
ORDER BY 
    sm.total_avail_qty DESC, 
    cm.total_comment_length DESC;
