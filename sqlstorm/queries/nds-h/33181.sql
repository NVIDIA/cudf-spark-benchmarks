
WITH  TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
    ORDER BY total_value DESC
    LIMIT 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 0
),
OrderLineStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY o.o_orderkey
),
PartMetrics AS (
    SELECT p.p_partkey, AVG(ps.ps_supplycost) AS avg_supplycost, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
)
SELECT 
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    o.o_orderkey,
    ols.total_price,
    pm.avg_supplycost,
    pm.supplier_count,
    CASE 
        WHEN o.o_orderstatus = 'O' THEN 'Open'
        ELSE 'Closed'
    END AS order_status,
    p.p_name
FROM TopSuppliers s
FULL OUTER JOIN CustomerOrders c ON s.s_suppkey = c.c_custkey
FULL OUTER JOIN orders o ON c.c_custkey = o.o_custkey 
FULL OUTER JOIN OrderLineStats ols ON o.o_orderkey = ols.o_orderkey
LEFT JOIN part p ON p.p_partkey = (ols.o_orderkey % (SELECT COUNT(p2.p_partkey) FROM part p2))
LEFT JOIN PartMetrics pm ON p.p_partkey = pm.p_partkey
WHERE pm.avg_supplycost IS NOT NULL
ORDER BY ols.total_price DESC, supplier_name, customer_name;
