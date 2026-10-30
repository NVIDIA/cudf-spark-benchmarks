WITH processed_part_names AS (
    SELECT 
        p.p_partkey,
        UPPER(SUBSTRING(p.p_name, 1, 10)) AS truncated_name,
        LENGTH(TRIM(p.p_comment)) AS comment_length
    FROM 
        part p
),
supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        CONCAT(s.s_address, ', ', n.n_name) AS full_address,
        REGEXP_REPLACE(s.s_comment, '[^a-zA-Z0-9 ]', '') AS sanitized_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    pp.truncated_name,
    pd.full_address,
    os.total_revenue,
    os.item_count,
    pp.comment_length
FROM 
    processed_part_names pp
JOIN 
    supplier_details pd ON pp.p_partkey = pd.s_suppkey
JOIN 
    order_summary os ON pd.s_suppkey = os.o_orderkey
WHERE 
    os.total_revenue > 10000
ORDER BY 
    pp.comment_length DESC, os.total_revenue ASC;
