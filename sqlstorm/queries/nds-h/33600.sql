WITH  TotalSales AS (
    SELECT c.c_custkey, 
           c.c_name, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 0
), RankedSales AS (
    SELECT c.custkey, 
           c.name, 
           ts.total_sales,
           RANK() OVER (ORDER BY ts.total_sales DESC) AS sales_rank
    FROM (SELECT DISTINCT c.c_custkey AS custkey, c.c_name AS name 
          FROM customer c) c
    LEFT JOIN TotalSales ts ON c.custkey = ts.c_custkey
), SupplierLineItems AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(l.l_quantity) AS total_quantity, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(l.l_quantity) > 1000
), RegionSales AS (
    SELECT r.r_name, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS region_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY r.r_name
)

SELECT 'Top Customers' AS category,
       r.name AS entity_name, 
       r.total_sales AS amount
FROM RankedSales r
WHERE r.sales_rank <= 10
UNION ALL
SELECT 'Supplier Sales' AS category,
       s.s_name AS entity_name, 
       s.total_value AS amount
FROM SupplierLineItems s
UNION ALL
SELECT 'Region Sales' AS category,
       rs.r_name AS entity_name, 
       rs.region_sales AS amount
FROM RegionSales rs
ORDER BY amount DESC;
