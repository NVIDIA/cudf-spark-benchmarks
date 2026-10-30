
WITH processed_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        LENGTH(p.p_name) AS name_length,
        UPPER(p.p_comment) AS uppercase_comment,
        CONCAT('Part: ', p.p_name, ' | Brand: ', p.p_brand) AS part_details
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
),
supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        REPLACE(s.s_address, 'Street', 'St.') AS abbreviated_address
    FROM 
        supplier s
    WHERE 
        CHAR_LENGTH(s.s_name) > 10
),
order_summaries AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
)
SELECT 
    pp.p_partkey,
    pp.part_details,
    si.s_name,
    si.abbreviated_address,
    os.o_orderkey,
    os.o_orderstatus,
    os.total_revenue
FROM 
    processed_parts pp
JOIN 
    partsupp ps ON pp.p_partkey = ps.ps_partkey
JOIN 
    supplier_info si ON ps.ps_suppkey = si.s_suppkey
JOIN 
    order_summaries os ON pp.p_partkey = os.o_orderkey
WHERE 
    pp.name_length > 20
ORDER BY 
    os.total_revenue DESC;
