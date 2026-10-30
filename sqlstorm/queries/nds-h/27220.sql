
WITH part_info AS (
    SELECT 
        p.p_partkey,
        INITCAP(p.p_name) AS formatted_name,
        SUBSTRING(p.p_comment, 1, 20) AS short_comment,
        LENGTH(p.p_name) AS name_length,
        p.p_retailprice
    FROM 
        part p
    WHERE 
        p.p_size > 10
),
supplier_info AS (
    SELECT 
        s.s_suppkey,
        UPPER(s.s_name) AS upper_name,
        TRIM(s.s_address) AS clean_address,
        CHAR_LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000
),
customer_info AS (
    SELECT 
        c.c_custkey,
        CONCAT('Customer: ', c.c_name) AS cust_label,
        LEFT(c.c_address, 30) AS address_excerpt,
        REPLACE(c.c_comment, 'old', 'new') AS updated_comment
    FROM 
        customer c
    WHERE 
        c.c_mktsegment = 'BUILDING'
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS line_count,
        SUM(o.o_totalprice) AS total_order_value,
        MAX(o.o_orderdate) AS latest_order_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    pi.formatted_name,
    si.upper_name,
    ci.cust_label,
    os.line_count,
    os.total_order_value,
    os.latest_order_date,
    pi.short_comment,
    si.clean_address,
    ci.address_excerpt,
    ci.updated_comment
FROM 
    part_info pi
JOIN 
    supplier_info si ON pi.p_partkey = si.s_suppkey
JOIN 
    customer_info ci ON si.s_suppkey = ci.c_custkey
JOIN 
    order_summary os ON ci.c_custkey = os.o_orderkey
WHERE 
    pi.name_length > 10 AND
    si.comment_length < 100
ORDER BY 
    os.total_order_value DESC, pi.formatted_name;
