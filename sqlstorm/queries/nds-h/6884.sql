
WITH SupplierOrders AS (
    SELECT s.s_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey
),
HighRevenueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, so.total_revenue
    FROM SupplierOrders so
    JOIN supplier s ON so.s_suppkey = s.s_suppkey
    WHERE so.total_revenue > (SELECT AVG(total_revenue) FROM SupplierOrders)
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierCustomerRevenue AS (
    SELECT hs.s_name, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM HighRevenueSuppliers hs
    JOIN partsupp ps ON hs.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY hs.s_name, c.c_name
)
SELECT scr.s_name, scr.c_name, scr.revenue
FROM SupplierCustomerRevenue scr
ORDER BY scr.revenue DESC
LIMIT 10;
