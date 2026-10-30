WITH  order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        COALESCE(NULLIF(MAX(os.total_revenue), 0), 0) AS max_revenue
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        order_summary os ON os.o_orderkey = o.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    c.c_name,
    c.order_count,
    CASE 
        WHEN c.max_revenue = 0 THEN 'No Revenue'
        ELSE CONCAT('Max Revenue: $', CAST(c.max_revenue AS VARCHAR(20)))
    END AS revenue_info,
    RANK() OVER (ORDER BY c.order_count DESC, c.max_revenue DESC) AS customer_rank
FROM 
    customer_orders c
WHERE 
    c.order_count > 5
    AND c.max_revenue IS NOT NULL
ORDER BY 
    c.order_count DESC, 
    c.max_revenue DESC
LIMIT 10;