WITH StringBenchmark AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name,
        CONCAT(UPPER(SUBSTRING(p.p_name, 1, 3)), LOWER(SUBSTRING(p.p_name, 4, 52))) AS formatted_name,
        REPLACE(s.s_name, 'Supplier', 'Vendor') AS modified_supplier_name,
        LENGTH(p.p_comment) AS comment_length,
        LEFT(p.p_comment, 10) AS comment_excerpt,
        LTRIM(RTRIM(p.p_comment)) AS trimmed_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_size BETWEEN 1 AND 10
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    sb.p_partkey,
    sb.formatted_name,
    sb.modified_supplier_name,
    co.total_orders,
    co.total_spent,
    co.last_order_date,
    sb.comment_length,
    sb.comment_excerpt,
    sb.trimmed_comment
FROM 
    StringBenchmark sb
LEFT JOIN 
    CustomerOrders co ON sb.p_partkey = co.c_custkey
ORDER BY 
    sb.p_partkey;
