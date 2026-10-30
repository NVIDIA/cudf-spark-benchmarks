WITH  RegionalSales AS (
    SELECT 
        r.r_regionkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
    GROUP BY r.r_regionkey
    UNION ALL
    SELECT 
        r.r_regionkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE r.r_name LIKE '%North%' 
    AND (l.l_shipmode = 'AIR' OR l.l_shipmode = 'TRUCK')
    AND (l.l_returnflag IS NULL OR l.l_returnflag = 'N')
    GROUP BY r.r_regionkey
),
RankedSales AS (
    SELECT 
        r.r_regionkey,
        r.total_sales,
        r.order_count,
        RANK() OVER (ORDER BY r.total_sales DESC) AS sales_rank
    FROM RegionalSales r
)

SELECT 
    r.r_name,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.order_count, 0) AS order_count,
    CASE WHEN s.sales_rank IS NULL THEN 'Not Ranked' ELSE CAST(s.sales_rank AS STRING) END AS sales_rank
FROM region r
LEFT JOIN RankedSales s ON r.r_regionkey = s.r_regionkey
ORDER BY r.r_regionkey;