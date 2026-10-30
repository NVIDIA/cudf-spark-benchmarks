
WITH regional_sales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        r.r_name
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        COALESCE(SUM(l.l_extendedprice), 0) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY COUNT(o.o_orderkey) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
top_customers AS (
    SELECT 
        cust.c_custkey,
        cust.c_name,
        cust.total_spent,
        cust.order_count,
        RANK() OVER (ORDER BY cust.total_spent DESC) AS sales_rank
    FROM 
        customer_orders cust
    WHERE 
        cust.order_count > 5
)
SELECT 
    r.region_name,
    tc.c_name,
    tc.total_spent,
    CASE 
        WHEN tc.total_spent > 10000 THEN 'High Value'
        WHEN tc.total_spent BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value,
    COUNT(DISTINCT n.n_nationkey) AS distinct_nations,
    COUNT(DISTINCT tc.c_custkey) AS total_customers
FROM 
    top_customers tc
JOIN 
    nation n ON tc.c_custkey = n.n_nationkey
JOIN 
    regional_sales r ON r.region_name = n.n_name
WHERE 
    tc.sales_rank <= 10
GROUP BY 
    r.region_name, tc.c_name, tc.total_spent
HAVING 
    COUNT(DISTINCT n.n_nationkey) IS NOT NULL
ORDER BY 
    r.region_name, tc.total_spent DESC;
