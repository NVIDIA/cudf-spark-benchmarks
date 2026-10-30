WITH  TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CumulativeOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
)
SELECT 
    c.c_name,
    COALESCE(SUM(co.total_value), 0) AS total_order_value,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    MAX(ts.total_cost) AS highest_supplier_cost,
    AVG(c.c_acctbal) AS average_customer_balance
FROM customer c
LEFT JOIN CumulativeOrders co ON c.c_custkey = co.o_custkey
LEFT JOIN lineitem l ON co.o_orderkey = l.l_orderkey
LEFT JOIN TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE co.order_rank <= 5 
  AND c.c_acctbal IS NOT NULL 
  AND COALESCE(ts.total_cost, 0) > 1000
GROUP BY c.c_name
HAVING AVG(c.c_acctbal) > 5000 
ORDER BY total_order_value DESC
LIMIT 10;
