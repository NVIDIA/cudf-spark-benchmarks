
WITH ProcessedData AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        CASE 
            WHEN LENGTH(p.p_name) > 20 THEN CONCAT(SUBSTRING(p.p_name, 1, 17), '...')
            ELSE p.p_name 
        END AS truncated_p_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    GROUP BY 
        l.l_orderkey, 
        l.l_partkey, 
        p.p_name, 
        s.s_name, 
        c.c_name
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 2
)
SELECT 
    p_name,
    supplier_name,
    customer_name,
    total_orders,
    total_revenue,
    TRIM(CONCAT('Total Revenue for ', supplier_name, ': ', total_revenue)) AS revenue_info
FROM 
    ProcessedData
ORDER BY 
    total_revenue DESC
LIMIT 10;
