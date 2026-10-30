
WITH RECURSIVE HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    JOIN HighValueSuppliers h ON s.s_suppkey = h.s_suppkey + 1
),
OrderSummary AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_partkey) AS part_count,
        MAX(CASE WHEN l.l_shipdate < DATE '1997-01-01' THEN l.l_discount ELSE NULL END) AS last_year_discount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
),
SupplierPartInfo AS (
    SELECT 
        ps.ps_partkey,
        s.s_comment AS supplier_comment,
        p.p_brand,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY ps.ps_supplycost DESC) AS rank
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
)
SELECT r.r_name, 
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(COALESCE(os.total_sales, 0)) AS total_sales_summary,
       MAX(COALESCE(spi.supplier_comment, 'No comment')) AS supplier_comments,
       COUNT(DISTINCT CASE WHEN n.n_name IS NOT NULL THEN n.n_nationkey END) AS unique_nations
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN OrderSummary os ON c.c_custkey = os.o_orderkey
LEFT JOIN SupplierPartInfo spi ON c.c_custkey = spi.ps_partkey
WHERE r.r_name LIKE 'N%'
GROUP BY r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 10 OR SUM(COALESCE(os.total_sales, 0)) > 100000
ORDER BY r.r_name DESC
LIMIT 10;
