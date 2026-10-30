WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_partkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F' AND o.o_orderdate >= '1997-01-01'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
FrequentOrders AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS order_count
    FROM orders o
    GROUP BY o.o_custkey
    HAVING COUNT(o.o_orderkey) > 5
)
SELECT hvc.c_custkey, hvc.c_name, COUNT(DISTINCT lo.l_orderkey) AS order_count,
       SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
       MAX(rs.total_cost) AS max_supplier_cost
FROM HighValueCustomers hvc
JOIN lineitem lo ON lo.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = hvc.c_custkey)
LEFT JOIN RankedSuppliers rs ON rs.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p))
JOIN FrequentOrders fo ON fo.o_custkey = hvc.c_custkey
GROUP BY hvc.c_custkey, hvc.c_name
ORDER BY total_revenue DESC
LIMIT 10;