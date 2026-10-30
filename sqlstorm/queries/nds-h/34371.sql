
WITH  Finance AS (
    SELECT c_custkey, c_name, c_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY c_nationkey ORDER BY c_acctbal DESC) AS rank
    FROM customer
    WHERE c_acctbal > 1000
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty IS NOT NULL
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) < 50000
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus = 'F'
),
CustomerBalance AS (
    SELECT c.c_custkey, c.c_name, COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS order_total
    FROM customer c
    LEFT JOIN lineitem l ON c.c_custkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    r.r_name, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(COALESCE(oc.order_total, 0)) AS avg_order_total,
    MIN(s.total_cost) AS min_supplier_cost,
    MAX(f.c_acctbal) AS max_balance
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN RecentOrders o ON o.o_custkey = c.c_custkey
LEFT JOIN CustomerBalance oc ON c.c_custkey = oc.c_custkey
LEFT JOIN TopSuppliers s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 10))
LEFT JOIN Finance f ON c.c_custkey = f.c_custkey
WHERE r.r_name IS NOT NULL AND c.c_acctbal > 0
GROUP BY r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY avg_order_total DESC;
