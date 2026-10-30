WITH Summary AS (
    SELECT 
        c.c_name AS customer_name,
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(l.l_quantity) AS total_quantity
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY c.c_name, n.n_name
),
RankedSummary AS (
    SELECT 
        customer_name,
        nation_name,
        total_revenue,
        order_count,
        total_quantity,
        DENSE_RANK() OVER (PARTITION BY nation_name ORDER BY total_revenue DESC) AS revenue_rank
    FROM Summary
)
SELECT 
    nation_name,
    COUNT(customer_name) AS num_customers,
    AVG(total_revenue) AS avg_revenue,
    SUM(order_count) AS total_orders,
    SUM(total_quantity) AS total_quantity_sold
FROM RankedSummary
WHERE revenue_rank <= 5
GROUP BY nation_name
ORDER BY total_orders DESC, avg_revenue DESC;