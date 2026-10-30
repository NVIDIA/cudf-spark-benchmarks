
WITH CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 0
),
SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
),
RevenueAnalysis AS (
    SELECT co.c_custkey, SUM(co.o_totalprice) AS total_revenue,
           COUNT(DISTINCT co.o_orderkey) AS order_count,
           MIN(co.o_orderdate) AS first_order_date,
           MAX(co.o_orderdate) AS last_order_date
    FROM CustomerOrders co
    GROUP BY co.c_custkey
),
RankedSuppliers AS (
    SELECT sp.s_suppkey, sp.s_name, sp.s_acctbal,
           DENSE_RANK() OVER (ORDER BY SUM(sp.ps_supplycost) DESC) AS supplier_rank
    FROM SupplierParts sp
    GROUP BY sp.s_suppkey, sp.s_name, sp.s_acctbal
)
SELECT r.r_name, r.r_comment,
       COALESCE(ra.total_revenue, 0) AS customer_revenue,
       sr.supplier_rank
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN RevenueAnalysis ra ON n.n_nationkey = ra.c_custkey
LEFT JOIN RankedSuppliers sr ON r.r_regionkey = sr.s_suppkey
WHERE r.r_name LIKE '%South%'
   OR sr.supplier_rank IS NOT NULL
ORDER BY r.r_name, customer_revenue DESC;
