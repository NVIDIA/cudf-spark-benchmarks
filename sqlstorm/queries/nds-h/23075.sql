WITH  CategoryHierarchy AS (
    SELECT 
        s_nationkey,
        SUM(CASE WHEN p_size IS NULL THEN 0 ELSE p_size END) AS total_size
    FROM supplier 
    JOIN partsupp ON supplier.s_suppkey = partsupp.ps_suppkey
    JOIN part ON partsupp.ps_partkey = part.p_partkey
    GROUP BY s_nationkey
),
SalesRank AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(COALESCE(l.l_extendedprice, 0) * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    SUM(CASE 
        WHEN ph.total_size IS NULL THEN 0 
        ELSE ph.total_size 
    END) AS total_supplies,
    COALESCE(MIN(sr.total_sales), 0) AS min_sales,
    COALESCE(MAX(sr.total_sales), 0) AS max_sales
FROM region r
LEFT JOIN (
    SELECT 
        nh.s_nationkey,
        SUM(nh.total_size) AS total_size
    FROM CategoryHierarchy nh
    GROUP BY nh.s_nationkey
) ph ON r.r_regionkey = ph.s_nationkey
FULL OUTER JOIN SalesRank sr ON sr.c_custkey = r.r_regionkey
WHERE r.r_name ILIKE '%eu%'
GROUP BY r.r_name
HAVING COUNT(sr.c_custkey) FILTER (WHERE sr.sales_rank = 1) > 1
ORDER BY r.r_name ASC NULLS LAST;
