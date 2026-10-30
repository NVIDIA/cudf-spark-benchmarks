WITH SupplierQuantities AS (
    SELECT s.s_suppkey, SUM(ps.ps_availqty) AS total_avail_qty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
NationSuppliers AS (
    SELECT n.n_name, sq.s_suppkey, sq.total_avail_qty
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN SupplierQuantities sq ON s.s_suppkey = sq.s_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
OrderDetails AS (
    SELECT co.c_custkey, co.c_name, nos.n_name, nos.total_avail_qty, 
           ROW_NUMBER() OVER (PARTITION BY co.c_custkey ORDER BY co.total_order_value DESC) AS order_rank
    FROM CustomerOrders co
    JOIN NationSuppliers nos ON co.c_custkey = nos.s_suppkey
)
SELECT od.c_name, od.n_name, od.total_avail_qty, od.order_rank
FROM OrderDetails od
WHERE od.order_rank <= 5
ORDER BY od.c_name, od.n_name;
