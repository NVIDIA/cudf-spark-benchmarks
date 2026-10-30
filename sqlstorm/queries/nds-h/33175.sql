
WITH  SalesCTE AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_shipdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey, c.c_name, c.c_custkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
RegionSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(sc.total_sales) AS total_region_sales
    FROM SalesCTE sc
    JOIN supplier s ON sc.o_orderkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY n.n_name
)
SELECT 
    r.r_name,
    COALESCE(rs.total_region_sales, 0) AS sales_total,
    CASE 
        WHEN rs.total_region_sales > 5000 THEN 'High'
        WHEN rs.total_region_sales BETWEEN 1000 AND 5000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM region r
LEFT JOIN RegionSales rs ON r.r_name = rs.nation_name
ORDER BY sales_total DESC;
