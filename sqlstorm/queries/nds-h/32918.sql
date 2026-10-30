
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal IS NOT NULL AND sh.level < 10
),
TotalPrice AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1995-01-01' AND '1996-12-31'
    GROUP BY o.o_orderkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal > (
        SELECT AVG(c2.c_acctbal) 
        FROM customer c2
    )
),
NationSupplier AS (
    SELECT n.n_nationkey, n.n_name, COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    ns.supplier_count,
    CASE 
        WHEN SUM(l.l_extendedprice) IS NULL THEN 'No Sales'
        ELSE 'Sales Exist'
    END AS sales_status,
    ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY SUM(l.l_extendedprice) DESC) AS rank
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
FULL OUTER JOIN NationSupplier ns ON p.p_brand = CAST(ns.n_nationkey AS STRING)
WHERE 
    p.p_size BETWEEN 10 AND 20
    AND (p.p_retailprice IS NOT NULL OR l.l_discount < 0.1)
GROUP BY p.p_name, ns.supplier_count, p.p_type
HAVING SUM(l.l_quantity) > 100
ORDER BY total_quantity DESC
LIMIT 50;
