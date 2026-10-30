WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
),
OrderCounts AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM orders o
    GROUP BY o.o_custkey
),
HighValueOrders AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '1997-01-01'
    GROUP BY l.l_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
)
SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(p.ps_supplycost) AS total_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS high_value_order_count,
    SUM(hv.total_value) AS high_value_sum
FROM nation n
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN orders o ON o.o_custkey = c.c_custkey
LEFT JOIN lineitem l ON l.l_orderkey = o.o_orderkey
LEFT JOIN partsupp p ON p.ps_partkey = l.l_partkey
LEFT JOIN RankedSuppliers rs ON rs.s_suppkey = p.ps_suppkey AND rs.rnk = 1
LEFT JOIN HighValueOrders hv ON hv.l_orderkey = l.l_orderkey
WHERE p.ps_availqty IS NOT NULL
GROUP BY n.n_name
HAVING SUM(CASE WHEN o.o_orderstatus = 'O' THEN 1 ELSE 0 END) > 0
ORDER BY n.n_name DESC;