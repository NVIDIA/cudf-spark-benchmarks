WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER(PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 0
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           SUM(l.l_quantity * l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
    HAVING SUM(l.l_quantity * l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierAndOrderSummary AS (
    SELECT o.o_orderkey, s.s_suppkey, s.s_name, SUM(l.l_quantity) AS total_quantity
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 5000
    GROUP BY o.o_orderkey, s.s_suppkey, s.s_name
)
SELECT r.r_name, COUNT(DISTINCT h.o_orderkey) AS high_value_order_count, 
       SUM(s.total_quantity) AS total_quantity_sold, 
       AVG(s.total_quantity) AS avg_quantity_per_order, 
       COUNT(DISTINCT rs.s_suppkey) AS unique_supplier_count
FROM HighValueOrders h
JOIN SupplierAndOrderSummary s ON h.o_orderkey = s.o_orderkey
JOIN supplier rs ON s.s_suppkey = rs.s_suppkey
JOIN nation n ON rs.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE rs.s_name IN (SELECT s_name FROM RankedSuppliers WHERE rn <= 5)
GROUP BY r.r_name
ORDER BY high_value_order_count DESC, total_quantity_sold DESC;
