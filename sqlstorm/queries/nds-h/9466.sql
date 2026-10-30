WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name,
           RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
CustomerOrderStats AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
LineItemTotals AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
TopParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT r.nation_name, COUNT(DISTINCT r.s_suppkey) AS total_suppliers, 
       SUM(Coalesce(cos.total_orders, 0)) AS total_orders,
       SUM(Coalesce(cos.total_spent, 0)) AS total_spent,
       SUM(COALESCE(lt.total_revenue, 0)) AS total_revenue,
       SUM(COALESCE(tp.total_available, 0)) AS total_parts_available
FROM RankedSuppliers r
LEFT JOIN CustomerOrderStats cos ON r.s_suppkey = cos.c_custkey
LEFT JOIN LineItemTotals lt ON r.s_suppkey = lt.l_orderkey
LEFT JOIN TopParts tp ON r.s_suppkey = tp.ps_partkey
GROUP BY r.nation_name
HAVING COUNT(DISTINCT r.s_suppkey) > 10
ORDER BY total_spent DESC;
