WITH processed_parts AS (
    SELECT 
        p.p_partkey, 
        UPPER(p.p_name) AS upper_name, 
        LOWER(p.p_comment) AS lower_comment, 
        TRIM(p.p_container) AS trimmed_container, 
        REPLACE(p.p_comment, 'old', 'new') AS replaced_comment
    FROM 
        part p
),
supplier_info AS (
    SELECT 
        s.s_suppkey, 
        CONCAT(s.s_name, ' - ', s.s_address) AS supplier_details, 
        LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
),
order_summary AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS total_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    pp.upper_name, 
    si.supplier_details, 
    os.total_revenue, 
    os.total_items, 
    pp.replaced_comment
FROM 
    processed_parts pp
JOIN 
    partsupp ps ON pp.p_partkey = ps.ps_partkey
JOIN 
    supplier_info si ON ps.ps_suppkey = si.s_suppkey
JOIN 
    order_summary os ON os.o_orderkey = ps.ps_partkey
WHERE 
    pp.trimmed_container LIKE 'BOX%'
ORDER BY 
    os.total_revenue DESC
LIMIT 10;
