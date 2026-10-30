WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
AggregatedSales AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY l.l_partkey
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size,
           RANK() OVER (ORDER BY a.total_sales DESC) AS rank
    FROM part p
    JOIN AggregatedSales a ON p.p_partkey = a.l_partkey
    WHERE p.p_size > 10
),
SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name IN (SELECT DISTINCT n_name FROM nation WHERE n_regionkey = 1)
),
FinalOutput AS (
    SELECT th.p_partkey, th.p_name, si.s_name, si.s_acctbal,
           th.rank, 
           CASE 
               WHEN si.s_acctbal IS NULL THEN 'No Account Balance'
               ELSE CAST(si.s_acctbal AS STRING)
           END AS account_balance
    FROM TopParts th
    LEFT JOIN SupplierInfo si ON th.p_brand = SUBSTRING(si.s_name FROM 1 FOR 3)
    WHERE th.rank <= 10
)
SELECT f.*, 
       CASE 
           WHEN f.account_balance IS NOT NULL THEN 'Available' 
           ELSE 'Unavailable' 
       END AS availability
FROM FinalOutput f
ORDER BY f.rank, f.p_partkey;