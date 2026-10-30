WITH  CustomerCTE AS (
    SELECT c_custkey, c_name, c_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY c_nationkey ORDER BY c_acctbal DESC) AS rank_acctbal
    FROM customer
    WHERE c_acctbal IS NOT NULL
),
TotalOrders AS (
    SELECT o_custkey, COUNT(o_orderkey) AS order_count
    FROM orders
    GROUP BY o_custkey
),
OrderSummary AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           AVG(l.l_quantity) AS avg_quantity, 
           COUNT(o.o_orderkey) AS total_orders, 
           DENSE_RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY o.o_custkey
),
SupplierDetails AS (
    SELECT s.s_suppkey, COUNT(ps.ps_partkey) AS parts_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
    HAVING COUNT(ps.ps_partkey) > 0
)
SELECT DISTINCT c.c_name, c.c_acctbal, 
       COALESCE(o.total_revenue, 0) AS total_revenue,
       s.parts_count, 
       CASE 
           WHEN c.c_acctbal IS NULL THEN 'Unknown Balance' 
           ELSE 'Known Balance' 
       END AS acctbal_status,
       (SELECT COUNT(*) FROM nation n WHERE n.n_nationkey = c.c_nationkey) AS nation_count
FROM customer c
LEFT JOIN OrderSummary o ON c.c_custkey = o.o_custkey
LEFT JOIN SupplierDetails s ON s.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_container LIKE '%BOX%'
    ORDER BY ps.ps_supplycost DESC
    LIMIT 1 OFFSET 1
)
WHERE c.c_nationkey IN (
    SELECT n.n_nationkey
    FROM nation n
    WHERE n.n_comment IS NOT NULL
)
AND c.c_custkey IN (SELECT c_custkey FROM TotalOrders WHERE order_count >= 5)
ORDER BY total_revenue DESC, c.c_name ASC
LIMIT 100;
