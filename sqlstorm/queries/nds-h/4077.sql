
WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01'
),
CustomerOrders AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT s.s_suppkey,
           s.s_name,
           p.p_partkey,
           SUM(ps.ps_availqty) AS total_available
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_partkey
)
SELECT co.c_name,
       co.total_orders,
       co.total_spent,
       SUM(sp.total_available) AS total_available_parts,
       SUM(CASE WHEN lo.l_discount > 0.10 THEN lo.l_extendedprice * (1 - lo.l_discount) ELSE 0 END) AS total_discounted_revenue,
       RANK() OVER (ORDER BY co.total_spent DESC) AS revenue_rank
FROM CustomerOrders co
LEFT JOIN lineitem lo ON co.c_custkey = lo.l_orderkey
LEFT JOIN SupplierParts sp ON lo.l_partkey = sp.p_partkey
WHERE co.total_orders > 0
  AND (co.total_spent IS NOT NULL OR co.total_orders > 1)
GROUP BY co.c_custkey, co.c_name, co.total_orders, co.total_spent
HAVING SUM(sp.total_available) > 100 
   OR (COALESCE(SUM(CASE WHEN lo.l_discount > 0.10 THEN lo.l_extendedprice * (1 - lo.l_discount) ELSE 0 END), 0) > 5000 AND co.total_orders > 5)
ORDER BY revenue_rank;
