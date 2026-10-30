WITH  SupplierPerformance AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank,
           r.r_name AS region_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE s.s_acctbal IS NOT NULL
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice
),
TopOrders AS (
    SELECT o.o_orderkey, o.o_totalprice,
           DENSE_RANK() OVER (ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
)

SELECT p.p_name, 
       sp.s_name AS supplier_name, 
       r.r_name AS region,
       COALESCE(AVG(dp.total_lineitem_value), 0) AS avg_order_value,
       COUNT(DISTINCT o.o_orderkey) AS total_orders,
       MAX(sp.s_acctbal) AS highest_supplier_balance
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier sp ON ps.ps_suppkey = sp.s_suppkey
LEFT JOIN nation n ON sp.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN OrderDetails dp ON dp.o_orderkey = ps.ps_partkey  
LEFT JOIN TopOrders o ON o.o_orderkey = dp.o_orderkey
WHERE p.p_size BETWEEN 10 AND 20
  AND sp.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
  AND r.r_name IS NOT NULL
GROUP BY p.p_name, sp.s_name, r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5 OR MAX(sp.s_acctbal) IS NOT NULL
ORDER BY p.p_name, total_orders DESC;