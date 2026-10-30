WITH SupplierSales AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * l.l_quantity) AS total_spend
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, co.order_count, co.total_revenue
    FROM CustomerOrders co
    JOIN customer c ON co.c_custkey = c.c_custkey
    WHERE co.total_revenue > 10000
), SupplierRankings AS (
    SELECT s.s_suppkey, s.s_name, ss.total_spend
    FROM SupplierSales ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE ss.total_spend > 50000
), FinalReport AS (
    SELECT hvc.c_name AS customer_name, hvc.order_count, hvc.total_revenue, sr.s_name AS supplier_name, sr.total_spend
    FROM HighValueCustomers hvc
    JOIN SupplierRankings sr ON hvc.total_revenue > sr.total_spend
)
SELECT *
FROM FinalReport
ORDER BY total_revenue DESC, total_spend DESC
LIMIT 10;
