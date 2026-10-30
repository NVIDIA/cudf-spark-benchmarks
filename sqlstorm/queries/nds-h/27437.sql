WITH processed_parts AS (
    SELECT 
        p.p_partkey,
        UPPER(p.p_name) AS part_name_upper,
        LOWER(p.p_comment) AS part_comment_lower,
        LENGTH(p.p_comment) AS comment_length,
        REPLACE(p.p_brand, 'OLD', 'NEW') AS updated_brand
    FROM 
        part p
),
supplier_data AS (
    SELECT 
        s.s_suppkey,
        TRIM(s.s_name) AS supplier_name,
        CONCAT(s.s_address, ', ', r.r_name) AS full_address,
        s.s_acctbal,
        LENGTH(s.s_comment) AS supplier_comment_length
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.s_acctbal > 1000
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 5000
)
SELECT 
    pp.part_name_upper,
    pp.part_comment_lower,
    pp.comment_length,
    pp.updated_brand,
    sd.supplier_name,
    sd.full_address,
    sd.s_acctbal,
    sd.supplier_comment_length,
    co.c_name,
    co.order_count,
    co.total_spent
FROM 
    processed_parts pp
JOIN 
    partsupp ps ON pp.p_partkey = ps.ps_partkey
JOIN 
    supplier_data sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    customer_orders co ON sd.s_suppkey = co.c_custkey
WHERE 
    pp.comment_length > 20
ORDER BY 
    pp.updated_brand, co.total_spent DESC;
