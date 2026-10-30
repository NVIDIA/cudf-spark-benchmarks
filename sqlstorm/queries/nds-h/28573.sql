
WITH processed_parts AS (
    SELECT 
        p.p_partkey,
        UPPER(p.p_name) AS processed_name,
        CONCAT(SUBSTRING(p.p_mfgr, 1, 3), '-', p.p_brand) AS mfgr_brand,
        ROUND(p.p_retailprice, 2) AS rounded_price,
        LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
    WHERE 
        p.p_size > 10
),
region_summary AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
order_analysis AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
)
SELECT 
    pp.processed_name,
    pp.mfgr_brand,
    pp.rounded_price,
    pp.comment_length,
    rs.r_name,
    rs.supplier_count,
    oa.total_orders,
    oa.total_spent,
    oa.last_order_date
FROM 
    processed_parts pp
JOIN 
    partsupp ps ON pp.p_partkey = ps.ps_partkey
JOIN 
    region_summary rs ON ps.ps_suppkey = rs.supplier_count
JOIN 
    order_analysis oa ON ps.ps_suppkey = oa.o_custkey
WHERE 
    pp.comment_length > 10
ORDER BY 
    pp.rounded_price DESC, 
    oa.total_spent DESC;
