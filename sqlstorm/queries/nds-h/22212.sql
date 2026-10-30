WITH RankedSuppliers AS (
    SELECT s_suppkey, s_name, s_nationkey,
           DENSE_RANK() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rank_acctbal
    FROM supplier
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_retailprice > (SELECT AVG(p_retailprice) FROM part WHERE p_size < 100)
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
),
OrderDetails AS (
    SELECT o.o_orderkey, l.l_partkey, l.l_orderkey, l.l_quantity, l.l_discount,
           CASE WHEN l.l_returnflag = 'R' THEN 'Returned' ELSE 'Not Returned' END AS return_status
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'P')
),
FinalReport AS (
    SELECT h.p_partkey, h.p_name, h.p_retailprice, d.o_orderkey,
           SUM(d.l_quantity * (1 - d.l_discount)) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY h.p_partkey ORDER BY SUM(d.l_quantity * (1 - d.l_discount)) DESC) AS sales_rank
    FROM HighValueParts h
    LEFT JOIN OrderDetails d ON h.p_partkey = d.l_partkey
    GROUP BY h.p_partkey, h.p_name, h.p_retailprice, d.o_orderkey
)
SELECT p.p_partkey, p.p_name, p.p_retailprice, COALESCE(SUM(s.total_sales), 0) AS total_sales,
       CASE WHEN SUM(s.total_sales) IS NULL THEN 'No Sales' ELSE 'Sales Recorded' END AS sales_status
FROM HighValueParts p
LEFT JOIN FinalReport s ON p.p_partkey = s.p_partkey
GROUP BY p.p_partkey, p.p_name, p.p_retailprice
ORDER BY p.p_retailprice DESC, total_sales DESC
LIMIT 10 OFFSET 5;
