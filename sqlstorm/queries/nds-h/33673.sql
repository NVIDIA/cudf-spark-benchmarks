WITH  CustomerCTE AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal > 1000
),
SupplierSales AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY s.s_suppkey, s.s_name
),
RegionSummary AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
)
SELECT r.r_name, COUNT(DISTINCT c.c_custkey) AS total_customers, 
       SUM(ss.total_sales) AS total_supplier_sales
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN SupplierSales ss ON ss.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
) OR ss.s_suppkey IS NULL
WHERE c.c_custkey IN (SELECT c_custkey FROM CustomerCTE WHERE rank <= 5)
GROUP BY r.r_name
ORDER BY total_customers DESC, total_supplier_sales DESC;