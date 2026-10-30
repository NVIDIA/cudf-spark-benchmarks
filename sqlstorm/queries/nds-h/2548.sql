WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders AS o
    JOIN 
        lineitem AS l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
),
customer_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer AS c
    LEFT JOIN 
        orders AS o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
high_value_customers AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.total_spent,
        cs.order_count,
        ROW_NUMBER() OVER (ORDER BY cs.total_spent DESC) AS value_rank
    FROM 
        customer_summary AS cs
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM customer_summary)
)
SELECT 
    hvc.c_name,
    hvc.total_spent,
    hvc.order_count,
    CASE 
        WHEN hvc.order_count > 5 THEN 'Frequent'
        ELSE 'Occasional'
    END AS customer_type,
    ro.total_order_value AS highest_order_value
FROM 
    high_value_customers AS hvc
LEFT JOIN 
    ranked_orders AS ro ON hvc.c_custkey = ro.o_custkey AND ro.order_rank = 1
WHERE 
    hvc.value_rank <= 10
ORDER BY 
    hvc.total_spent DESC, hvc.c_name;
