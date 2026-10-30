WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(ro.total_revenue) AS customer_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN RankedOrders ro ON o.o_orderkey = ro.o_orderkey
    GROUP BY c.c_custkey, c.c_name
    ORDER BY customer_revenue DESC
    LIMIT 10
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    rc.customer_revenue, 
    COALESCE(sd.supplier_value, 0) AS supplier_value, 
    rc.c_name
FROM TopCustomers rc
LEFT JOIN SupplierDetails sd ON rc.c_custkey = sd.s_suppkey
ORDER BY rc.customer_revenue DESC, supplier_value ASC;
