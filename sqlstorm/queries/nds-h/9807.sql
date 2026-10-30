WITH RankedSupplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
), HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           DENSE_RANK() OVER (ORDER BY c.c_acctbal DESC) as rank
    FROM customer c
    WHERE c.c_acctbal > 50000
), OrderStats AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) as total_sales,
           AVG(l.l_discount) as avg_discount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
), SupplierPartStats AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT s.s_suppkey) as num_suppliers, 
           AVG(s.s_acctbal) as avg_supplier_acctbal
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
)
SELECT r.r_name, SUM(oss.total_sales) as total_sales, COUNT(DISTINCT hc.c_custkey) as high_value_customers,
       AVG(sp.avg_supplier_acctbal) as avg_supplier_acctbal
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN OrderStats oss ON ps.ps_partkey = oss.o_orderkey
JOIN HighValueCustomers hc ON oss.total_sales > 1000000
JOIN SupplierPartStats sp ON ps.ps_partkey = sp.ps_partkey
WHERE s.s_acctbal > 100000
GROUP BY r.r_name
ORDER BY total_sales DESC;
