WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value,
        MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
Ranking AS (
    SELECT 
        cust.c_custkey,
        cust.c_name,
        cust.total_orders,
        cust.avg_order_value,
        RANK() OVER (ORDER BY cust.avg_order_value DESC) AS order_rank
    FROM CustomerOrderStats cust
)
SELECT 
    s.s_name AS supplier_name,
    s.total_avail_qty AS total_available_quantity,
    c.c_name AS customer_name,
    c.total_orders AS order_count,
    c.avg_order_value AS average_order_value,
    r.order_rank AS customer_rank
FROM SupplierStats s
FULL OUTER JOIN Ranking r ON s.s_suppkey = r.c_custkey
JOIN CustomerOrderStats c ON r.c_custkey = c.c_custkey
WHERE (s.total_avail_qty IS NOT NULL OR c.total_orders IS NOT NULL)
AND COALESCE(s.total_revenue, 0) > 10000
ORDER BY s.total_avail_qty DESC, c.avg_order_value ASC;
