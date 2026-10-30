WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        MAX(l.l_shipdate) AS last_ship_date,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_quantity > 0 
      AND l.l_shipdate >= '1997-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COALESCE(SUM(od.total_price), 0) AS total_spent
    FROM customer c
    LEFT JOIN OrderDetails od ON c.c_custkey = od.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
)
SELECT 
    c.c_name,
    c.c_acctbal,
    cs.s_name AS supplier_name,
    cs.s_acctbal AS supplier_acctbal,
    CASE 
        WHEN c.total_spent > 10000 THEN 'High Value Customer'
        WHEN c.total_spent BETWEEN 5000 AND 10000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS value_category
FROM CustomerDetails c
LEFT JOIN RankedSuppliers cs ON c.c_custkey = cs.s_suppkey
WHERE cs.rn = 1
  AND c.c_acctbal IS NOT NULL
ORDER BY c.total_spent DESC, c.c_name;