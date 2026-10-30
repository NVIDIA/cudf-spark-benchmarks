WITH  TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
), RankedSuppliers AS (
    SELECT s.*, RANK() OVER (ORDER BY total_cost DESC) AS rank
    FROM TopSuppliers s
), OrderDetails AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(od.total_revenue) AS total_spent, COUNT(od.o_orderkey) AS order_count
    FROM customer c
    JOIN OrderDetails od ON c.c_custkey = od.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(od.total_revenue) > 50000
)
SELECT cs.c_custkey, cs.c_name, cs.total_spent, COALESCE(rs.rank, 0) AS supplier_rank
FROM CustomerOrders cs
LEFT JOIN RankedSuppliers rs ON cs.c_custkey = rs.s_nationkey
WHERE cs.order_count > 5
ORDER BY cs.total_spent DESC, supplier_rank DESC
LIMIT 10;
