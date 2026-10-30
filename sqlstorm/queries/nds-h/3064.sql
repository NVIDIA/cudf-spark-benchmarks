
WITH RankedOrders AS (
    SELECT o.o_orderkey, 
           o.o_custkey, 
           o.o_totalprice, 
           o.o_orderdate, 
           o.o_orderpriority, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) as order_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O' 
      AND o.o_orderdate >= DATE '1997-01-01'
),
SupplierPartCounts AS (
    SELECT ps.ps_partkey, 
           COUNT(DISTINCT ps.ps_suppkey) as supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
HighValueSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 
                          WHERE s2.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = 1))
)
SELECT 
    p.p_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COALESCE(supplier_info.supplier_count, 0) AS total_suppliers,
    ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN RankedOrders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN SupplierPartCounts supplier_info ON p.p_partkey = supplier_info.ps_partkey
WHERE l.l_shipdate >= DATE '1997-01-01'
  AND l.l_returnflag = 'N'
GROUP BY p.p_name, supplier_info.supplier_count, p.p_type
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_revenue DESC, revenue_rank
LIMIT 10;
