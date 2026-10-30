
WITH  SupplierRank AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
), SalesData AS (
    SELECT o.o_orderkey, c.c_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, c.c_custkey
), FilteredSales AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sd.total_sales
    FROM SupplierRank s
    LEFT JOIN SalesData sd ON s.s_suppkey = sd.o_orderkey
    WHERE s.rank <= 5
), TopParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_supplycost) > (SELECT AVG(ps_supplycost) FROM partsupp)
), FinalResults AS (
    SELECT p.p_name, p.p_mfgr, p.p_container, 
           COALESCE(fs.total_sales, 0) AS sales,
           ROUND((p.p_retailprice * COALESCE(fs.total_sales, 0)) / NULLIF(COALESCE(fs.total_sales, 0), 0), 2) AS estimated_revenue
    FROM part p
    FULL OUTER JOIN FilteredSales fs ON p.p_partkey = fs.s_suppkey
    WHERE EXISTS (SELECT 1 FROM TopParts tp WHERE tp.ps_partkey = p.p_partkey)
)
SELECT *,
       CASE 
           WHEN sales > 10000 THEN 'High Seller'
           WHEN sales BETWEEN 5000 AND 10000 THEN 'Medium Seller'
           ELSE 'Low Seller'
       END AS sales_category
FROM FinalResults
ORDER BY estimated_revenue DESC, sales_category ASC;
