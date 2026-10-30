
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
), HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, 
           SUM(o.o_totalprice) AS total_spending
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F' 
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 5000
), OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           l.l_discount, l.l_tax,
           CASE 
               WHEN l.l_returnflag = 'R' THEN 'Returned' 
               ELSE 'Not Returned' 
           END AS return_status
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate < o.o_orderdate
), SupplierSummary AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_supplycost,
           COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
)
SELECT c.c_name AS customer_name, 
       SUM(od.o_totalprice) AS total_order_value,
       COALESCE(HS.unique_suppliers, 0) AS supplier_count,
       COUNT(DISTINCT od.o_orderkey) AS distinct_orders,
       SUM(CASE WHEN od.return_status = 'Returned' THEN 1 ELSE 0 END) AS returns_count
FROM HighValueCustomers c
LEFT JOIN OrderDetails od ON c.c_custkey = od.o_orderkey
LEFT JOIN SupplierSummary HS ON od.o_orderkey = HS.ps_partkey
WHERE od.l_discount > 0.1 OR od.l_tax > 0.1
GROUP BY c.c_name, HS.unique_suppliers
HAVING COUNT(DISTINCT od.o_orderkey) > 5
ORDER BY total_order_value DESC
LIMIT 10;
