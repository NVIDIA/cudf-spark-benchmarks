WITH  RegionSales AS (
    SELECT r.r_name, SUM(o.o_totalprice) AS total_sales
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'F'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY r.r_name
    UNION ALL
    SELECT r.r_name, SUM(o.o_totalprice) AS total_sales
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'F'
    AND l.l_shipdate < '1997-01-01'
    GROUP BY r.r_name
),
RankedSales AS (
    SELECT r.*, RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM RegionSales r
)
SELECT r.r_name, COALESCE(s.total_sales, 0) AS total_sales, s.sales_rank
FROM region r
LEFT JOIN RankedSales s ON r.r_name = s.r_name
WHERE s.sales_rank <= 10 OR s.sales_rank IS NULL
ORDER BY total_sales DESC, r.r_name;