WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
), RevenueAnalysis AS (
    SELECT cp.c_custkey, cp.c_name, SUM(cp.total_revenue) AS revenue
    FROM CustomerOrders cp
    GROUP BY cp.c_custkey, cp.c_name
    HAVING SUM(cp.total_revenue) > 10000
)
SELECT sp.s_name, p.p_name, r.revenue
FROM SupplierParts sp
JOIN part p ON sp.p_partkey = p.p_partkey
JOIN RevenueAnalysis r ON sp.s_suppkey = r.c_custkey
ORDER BY r.revenue DESC, sp.s_name ASC;