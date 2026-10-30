
WITH  TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
    ORDER BY total_cost DESC
    LIMIT 5
), 
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, 
           SUM(o.o_totalprice) AS total_spent,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
), 
SupplierParts AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, 
           ps.ps_supplycost, (ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size BETWEEN 10 AND 20
), 
AggregatedData AS (
    SELECT c.c_nationkey, COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate > DATE '1997-01-01' AND l.l_returnflag = 'N'
    GROUP BY c.c_nationkey
)
SELECT r.r_name,
       COALESCE(cd.order_count, 0) AS total_orders,
       COALESCE(cd.total_revenue, 0) AS total_revenue,
       ts.total_cost AS supplier_cost
FROM region r
LEFT JOIN AggregatedData cd ON r.r_regionkey = cd.c_nationkey
LEFT JOIN TopSuppliers ts ON ts.s_suppkey = (
    SELECT s.s_suppkey
    FROM supplier s 
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
    ORDER BY ps.ps_supplycost DESC
    LIMIT 1
)
ORDER BY total_orders DESC, total_revenue DESC;
