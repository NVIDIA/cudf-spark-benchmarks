WITH aggregated_data AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
ranked_data AS (
    SELECT 
        ad.p_partkey,
        ad.p_name,
        ad.total_quantity,
        ad.total_revenue,
        RANK() OVER (ORDER BY ad.total_revenue DESC) AS revenue_rank
    FROM 
        aggregated_data ad
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
top_customers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_orders,
        co.total_spent,
        RANK() OVER (ORDER BY co.total_spent DESC) AS customer_rank
    FROM 
        customer_orders co
)
SELECT 
    rc.revenue_rank,
    rc.p_name,
    rc.total_quantity,
    tc.customer_rank,
    tc.c_name,
    tc.total_orders,
    tc.total_spent
FROM 
    ranked_data rc
JOIN 
    top_customers tc ON rc.total_quantity > 100
WHERE 
    rc.revenue_rank <= 10 AND tc.customer_rank <= 5
ORDER BY 
    rc.revenue_rank, tc.total_spent DESC;
