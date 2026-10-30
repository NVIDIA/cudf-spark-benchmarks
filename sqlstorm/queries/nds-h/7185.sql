
WITH TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_cost DESC
    LIMIT 10
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 1000
),
HighValueLineItems AS (
    SELECT l.l_orderkey, COUNT(*) AS item_count, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM lineitem l
    WHERE l.l_shipdate >= '1997-01-01'
    GROUP BY l.l_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
)
SELECT s.s_name AS supplier_name, c.c_name AS customer_name, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue, 
       COUNT(DISTINCT o.o_orderkey) AS order_count
FROM HighValueLineItems h
JOIN orders o ON h.l_orderkey = o.o_orderkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN TopSuppliers s ON l.l_suppkey = s.s_suppkey
GROUP BY s.s_name, c.c_name
ORDER BY revenue DESC;
