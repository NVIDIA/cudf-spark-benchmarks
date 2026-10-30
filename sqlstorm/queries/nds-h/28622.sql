WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_by_price
    FROM 
        part p
), 
suppliers_with_comments AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_comment,
        LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
    WHERE 
        LOWER(s.s_comment) LIKE '%quality%'
),
order_summaries AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_linenumber) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    rp.p_name AS part_name,
    rp.p_brand AS brand,
    rp.p_retailprice AS retail_price,
    swc.s_name AS supplier_name,
    swc.comment_length AS supplier_comment_length,
    os.total_price AS order_total,
    os.item_count AS number_of_items,
    r.r_name AS region_name
FROM 
    ranked_parts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    supplier sw ON ps.ps_suppkey = sw.s_suppkey
JOIN 
    suppliers_with_comments swc ON sw.s_suppkey = swc.s_suppkey
JOIN 
    customer c ON sw.s_nationkey = c.c_nationkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    order_summaries os ON os.o_orderkey = c.c_custkey
WHERE 
    rp.rank_by_price <= 5
ORDER BY 
    rp.p_brand, rp.p_retailprice DESC;
