WITH SupplierRevenue AS (
    SELECT s.s_suppkey, 
           SUM(ps.ps_supplycost * l.l_quantity) AS total_revenue,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY s.s_suppkey
), 

CustomerOrders AS (
    SELECT c.c_custkey, 
           COUNT(DISTINCT o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),

RankedSuppliers AS (
    SELECT sr.s_suppkey,
           sr.total_revenue,
           sr.order_count,
           RANK() OVER (ORDER BY sr.total_revenue DESC) AS revenue_rank
    FROM SupplierRevenue sr
),

RankedCustomers AS (
    SELECT co.c_custkey,
           co.total_orders,
           co.total_spent,
           RANK() OVER (ORDER BY co.total_spent DESC) AS spend_rank
    FROM CustomerOrders co
)

SELECT rs.s_suppkey, 
       rs.total_revenue,
       rc.c_custkey,
       rc.total_spent,
       CASE 
           WHEN rc.total_spent IS NULL THEN 'No Orders'
           WHEN rs.order_count > 10 THEN 'High Volume'
           ELSE 'Low Volume'
       END AS order_volume_category
FROM RankedSuppliers rs
FULL OUTER JOIN RankedCustomers rc ON rs.revenue_rank = rc.spend_rank
WHERE (rc.total_orders IS NULL OR rc.total_orders > 5) 
  AND (rs.total_revenue IS NOT NULL OR rc.total_spent IS NOT NULL)
ORDER BY rs.total_revenue DESC NULLS LAST, rc.total_spent DESC NULLS LAST;
