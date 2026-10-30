
WITH CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
NationOrderStats AS (
    SELECT n.n_nationkey, n.n_name, SUM(co.order_count) AS total_orders
    FROM nation n
    JOIN CustomerOrders co ON n.n_nationkey = co.c_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
TopParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 5000
    GROUP BY ps.ps_partkey
),
OrderDetails AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_discount,
           LAG(l.l_extendedprice, 1, 0) OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS previous_price,
           l.l_extendedprice
    FROM lineitem l
    WHERE l.l_shipdate >= '1997-01-01'
),
FinalStats AS (
    SELECT co.c_custkey, co.c_name, ns.total_orders, 
           SUM(od.l_quantity * (od.l_extendedprice - od.l_extendedprice * od.l_discount)) AS total_spent
    FROM CustomerOrders co
    LEFT JOIN OrderDetails od ON co.c_custkey = od.l_orderkey
    LEFT JOIN NationOrderStats ns ON co.c_nationkey = ns.n_nationkey
    WHERE COALESCE(ns.total_orders, 0) > 0
    GROUP BY co.c_custkey, co.c_name, ns.total_orders
)
SELECT f.c_custkey, f.c_name, f.total_orders,
       COALESCE(f.total_spent, 0) AS total_spent,
       CASE WHEN f.total_spent IS NULL THEN 'No Spending' ELSE 'Active Customer' END AS customer_status
FROM FinalStats f
ORDER BY f.total_orders DESC, total_spent DESC
LIMIT 10;
