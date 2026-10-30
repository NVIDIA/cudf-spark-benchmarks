
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
),
TotalSales AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY l.l_partkey
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, 
           CASE 
               WHEN MAX(r.total_sales) IS NULL THEN 'No Sales'
               ELSE 'Sales Present'
           END AS sales_status
    FROM part p
    LEFT JOIN TotalSales r ON p.p_partkey = r.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
    HAVING COUNT(DISTINCT p.p_size) > 5
),
SupplierWithStatus AS (
    SELECT s.s_suppkey, s.s_name, 
        CASE 
            WHEN s.s_acctbal < 1000 THEN 'Low'
            WHEN s.s_acctbal BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS balance_status, 
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_comment LIKE '%reliable%'
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
)
SELECT hs.p_partkey, hs.p_name, hs.p_brand, 
       ss.s_name, ss.balance_status, ss.unique_parts,
       COALESCE(hs.sales_status, 'No Information') AS sales_info
FROM HighValueParts hs
FULL OUTER JOIN SupplierWithStatus ss ON hs.p_partkey = ss.unique_parts 
WHERE (ss.unique_parts IS NULL OR ss.unique_parts > 10)
AND (hs.p_brand IS NOT NULL OR ss.balance_status = 'High')
ORDER BY hs.p_partkey, ss.balance_status DESC;
