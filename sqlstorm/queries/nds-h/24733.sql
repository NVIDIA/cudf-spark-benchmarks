WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_linenumber) AS line_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
CustomerSegment AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'No Balance'
            WHEN c.c_acctbal < 500 THEN 'Low Value'
            WHEN c.c_acctbal BETWEEN 500 AND 2000 THEN 'Medium Value'
            ELSE 'High Value'
        END AS segment
    FROM customer c
)
SELECT 
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    COALESCE(MIN(s.s_name), 'No Supplier') AS supplier_name,
    cs.segment AS customer_segment,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    CASE 
        WHEN SUM(l.l_quantity) > 100 THEN 'Bulk Order'
        ELSE 'Normal Order'
    END AS order_type
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN RankedSuppliers s ON s.s_suppkey = l.l_suppkey AND s.rn = 1
JOIN HighValueOrders o ON o.o_custkey = l.l_orderkey
JOIN CustomerSegment cs ON cs.c_custkey = o.o_custkey
WHERE p.p_retailprice IS NOT NULL
AND (l.l_returnflag = 'N' OR l.l_returnflag IS NULL)
GROUP BY p.p_name, cs.segment
HAVING AVG(l.l_discount) < 0.15
ORDER BY total_quantity DESC, avg_price DESC
LIMIT 20;
