WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, COUNT(ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
), HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 5000
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
), TopRegions AS (
    SELECT n.n_regionkey, r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_regionkey, r.r_name
    HAVING COUNT(DISTINCT s.s_suppkey) > 5
), DetailedLineItems AS (
    SELECT li.l_orderkey, li.l_partkey, li.l_suppkey, li.l_quantity, li.l_extendedprice, li.l_discount, li.l_tax, s.s_name, p.p_name
    FROM lineitem li
    JOIN supplier s ON li.l_suppkey = s.s_suppkey
    JOIN partsupp ps ON li.l_partkey = ps.ps_partkey AND li.l_suppkey = ps.ps_suppkey
    JOIN part p ON li.l_partkey = p.p_partkey
)
SELECT 
    hvc.c_custkey, 
    hvc.c_name, 
    r.r_name AS region_name, 
    COUNT(DISTINCT dli.l_orderkey) AS total_orders,
    SUM(dli.l_extendedprice * (1 - dli.l_discount)) AS total_revenue,
    AVG(dli.l_quantity) AS avg_quantity,
    MAX(s.part_count) AS max_parts_supplied
FROM HighValueCustomers hvc
JOIN TopRegions r ON hvc.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderstatus = 'O') 
JOIN DetailedLineItems dli ON hvc.c_custkey = dli.l_orderkey
JOIN RankedSuppliers s ON dli.l_suppkey = s.s_suppkey
GROUP BY hvc.c_custkey, hvc.c_name, r.r_name
ORDER BY total_revenue DESC
LIMIT 10;
