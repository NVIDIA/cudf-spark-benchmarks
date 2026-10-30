WITH StringStats AS (
    SELECT 
        p.p_brand,
        SUM(LENGTH(p.p_name)) AS total_length_name,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
        AVG(LENGTH(ps_comment)) AS avg_partsupp_comment_length
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_brand
),
CustomerStats AS (
    SELECT 
        c.c_nationkey,
        SUM(LENGTH(c.c_name)) AS total_length_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        AVG(LENGTH(c.c_comment)) AS avg_customer_comment_length
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
)
SELECT 
    r.r_name,
    ss.total_length_name AS total_length_part_names,
    cs.total_length_name AS total_length_customer_names,
    r.r_comment,
    ss.unique_suppliers,
    cs.total_orders,
    ss.avg_partsupp_comment_length,
    cs.avg_customer_comment_length
FROM 
    region r
LEFT JOIN 
    StringStats ss ON (ss.p_brand LIKE '%' || r.r_name || '%')
LEFT JOIN 
    CustomerStats cs ON (cs.c_nationkey = r.r_regionkey)
WHERE 
    r.r_name IS NOT NULL  
ORDER BY 
    ss.total_length_name DESC, cs.total_orders DESC;
