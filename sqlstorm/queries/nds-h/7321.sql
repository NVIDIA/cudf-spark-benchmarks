
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1996-01-01' 
      AND o.o_orderdate < DATE '1996-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(roi.total_revenue) AS total_spent,
        RANK() OVER (ORDER BY SUM(roi.total_revenue) DESC) AS customer_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN RankedOrders roi ON o.o_orderkey = roi.o_orderkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT
    rc.c_name AS cust_name,
    rc.total_spent,
    r.r_name AS region
FROM TopCustomers rc
JOIN supplier s ON rc.c_custkey = s.s_nationkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE rc.customer_rank <= 10
ORDER BY rc.total_spent DESC;
