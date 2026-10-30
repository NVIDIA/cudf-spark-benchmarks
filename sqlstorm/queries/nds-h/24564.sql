WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
), 
TopNations AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY n.n_nationkey, n.n_name
    HAVING COUNT(DISTINCT s.s_suppkey) > (
        SELECT AVG(supplier_count)
        FROM (
            SELECT COUNT(DISTINCT s.s_suppkey) AS supplier_count
            FROM supplier s
            GROUP BY s.s_nationkey
        ) AS avg_counts
    )
), 
OrderLineItems AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F' AND l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
), 
HighValueOrders AS (
    SELECT oli.o_orderkey, oli.revenue
    FROM OrderLineItems oli
    JOIN TopNations tn ON tn.supplier_count > 1
    WHERE oli.revenue > (SELECT AVG(revenue) FROM OrderLineItems)
), 
SupplierOrderStats AS (
    SELECT s.s_suppkey, s.s_name, COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(CASE WHEN o.o_orderstatus = 'F' THEN 1 ELSE 0 END) AS fulfilled_orders
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderkey IS NOT NULL OR l.l_discount IS NOT NULL
    GROUP BY s.s_suppkey, s.s_name
)

SELECT tn.n_name, s.s_name, s.order_count, s.fulfilled_orders
FROM TopNations tn
JOIN SupplierOrderStats s ON tn.n_nationkey = s.s_suppkey
WHERE s.order_count > 0
ORDER BY tn.n_name, s.fulfilled_orders DESC, s.order_count DESC
LIMIT 10;