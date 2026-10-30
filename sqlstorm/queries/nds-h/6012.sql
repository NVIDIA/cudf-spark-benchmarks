WITH SupplierTotals AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
HighCostSuppliers AS (
    SELECT s_total.s_suppkey, s.s_name, s.s_address, s.s_phone, s_total.total_cost
    FROM SupplierTotals s_total
    JOIN supplier s ON s_total.s_suppkey = s.s_suppkey
    WHERE s_total.total_cost > (
        SELECT AVG(total_cost)
        FROM SupplierTotals
    )
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
)
SELECT h.s_name, h.s_address, h.s_phone, co.c_name, co.order_count
FROM HighCostSuppliers h
JOIN CustomerOrders co ON h.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        WHERE o.o_orderstatus = 'O'
    )
)
ORDER BY h.total_cost DESC, co.order_count DESC
LIMIT 10;
