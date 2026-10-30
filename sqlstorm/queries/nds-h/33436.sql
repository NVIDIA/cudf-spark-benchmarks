WITH  RegionalSales AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01' 
    GROUP BY r.r_regionkey, r.r_name
    UNION ALL
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(o.o_totalprice),
        COUNT(DISTINCT c.c_custkey)
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    RIGHT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate < DATE '1997-01-01'
    GROUP BY r.r_regionkey, r.r_name
), RankedSales AS (
    SELECT 
        r.r_name,
        r.total_sales,
        r.customer_count,
        RANK() OVER (ORDER BY r.total_sales DESC) AS sales_rank
    FROM RegionalSales r
)
SELECT 
    r.r_name,
    r.total_sales,
    r.customer_count,
    CASE 
        WHEN r.total_sales IS NULL THEN 'No Sales'
        WHEN r.total_sales >= 100000 THEN 'High Volume'
        WHEN r.total_sales < 100000 AND r.total_sales >= 50000 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS sales_category
FROM RankedSales r
WHERE r.sales_rank <= 10
ORDER BY r.sales_rank;