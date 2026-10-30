WITH processed_strings AS (
    SELECT 
        p.p_partkey,
        UPPER(p.p_name) AS upper_name,
        LOWER(p.p_comment) AS lower_comment,
        LENGTH(p.p_comment) AS comment_length,
        TRIM(p.p_type) AS trimmed_type,
        CONCAT('Brand: ', p.p_brand, ', Type: ', TRIM(p.p_type)) AS brand_type
    FROM 
        part p
    WHERE 
        p.p_size > 0
),
supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_phone,
        s.s_acctbal,
        SUBSTRING(s.s_address, 1, 20) AS short_address
    FROM 
        supplier s
),
order_summary AS (
    SELECT
        o.o_orderkey,
        COUNT(l.l_orderkey) AS item_count,
        SUM(l.l_extendedprice) AS total_price,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    ps.p_partkey,
    ps.upper_name,
    ps.lower_comment,
    ps.comment_length,
    ps.trimmed_type,
    ps.brand_type,
    si.s_name,
    si.s_phone,
    os.item_count,
    os.total_price,
    os.last_order_date
FROM 
    processed_strings ps
JOIN 
    partsupp psu ON ps.p_partkey = psu.ps_partkey
JOIN 
    supplier_info si ON psu.ps_suppkey = si.s_suppkey
JOIN 
    order_summary os ON os.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name LIKE '%Corp%') LIMIT 1)
WHERE 
    ps.comment_length > 10 AND
    ps.brand_type LIKE '%Brand%'
ORDER BY 
    ps.brand_type ASC, os.total_price DESC;
