WITH SalesSummary AS (
    SELECT
        c.c_mktsegment,
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        COUNT(DISTINCT l.l_linenumber) AS line_item_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY c.c_mktsegment, n.n_name
), RankedSales AS (
    SELECT
        s.c_mktsegment,
        s.nation_name,
        s.total_sales,
        s.order_count,
        s.line_item_count,
        RANK() OVER (PARTITION BY s.c_mktsegment ORDER BY s.total_sales DESC) AS sales_rank
    FROM SalesSummary s
)
SELECT
    r.c_mktsegment,
    r.nation_name,
    r.total_sales,
    r.order_count,
    r.line_item_count
FROM RankedSales r
WHERE r.sales_rank <= 10
ORDER BY r.c_mktsegment, r.total_sales DESC;
