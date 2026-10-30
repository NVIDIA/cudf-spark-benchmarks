WITH  RegionSales AS (
    SELECT r.r_regionkey,
           r.r_name,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
    GROUP BY r.r_regionkey, r.r_name
),
FilteredSales AS (
    SELECT r.r_regionkey,
           r.r_name,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY r.r_regionkey, r.r_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > (
        SELECT AVG(total_sales)
        FROM (
            SELECT SUM(l_extendedprice * (1 - l_discount)) AS total_sales
            FROM lineitem
            JOIN orders ON lineitem.l_orderkey = orders.o_orderkey
            WHERE orders.o_orderdate >= '1997-01-01' AND orders.o_orderdate < '1997-12-31'
            GROUP BY orders.o_orderkey
        ) AS avg_sales
    )
)
SELECT r.r_regionkey,
       r.r_name,
       COALESCE(rs.total_sales, 0) AS total_region_sales,
       COALESCE(fs.total_sales, 0) AS filtered_sales,
       CASE 
           WHEN COALESCE(fs.total_sales, 0) > 0 THEN 'Above Average'
           ELSE 'Below Average'
       END AS sales_category
FROM region r
LEFT JOIN RegionSales rs ON r.r_regionkey = rs.r_regionkey
LEFT JOIN FilteredSales fs ON r.r_regionkey = fs.r_regionkey
ORDER BY total_region_sales DESC, r.r_name;