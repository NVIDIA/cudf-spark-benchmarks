
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1993-01-01'
      AND o.o_orderdate < DATE '1994-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate, c.c_name, c.c_nationkey
), TopCustomers AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        o.c_name AS customer_name,
        o.total_revenue
    FROM RankedOrders o
    JOIN customer c ON o.o_orderkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE o.revenue_rank <= 5
)
SELECT 
    region,
    nation,
    COUNT(customer_name) AS top_customers_count,
    SUM(total_revenue) AS total_revenue_generated
FROM TopCustomers
GROUP BY region, nation
ORDER BY region, total_revenue_generated DESC;
