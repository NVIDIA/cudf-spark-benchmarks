WITH RegionalSales AS (
    SELECT
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM
        region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE
        r.r_name IS NOT NULL
        AND (o.o_orderstatus IS NULL OR o.o_orderstatus = 'O')
        AND NOT EXISTS (
            SELECT 1
            FROM customer c
            WHERE c.c_custkey = o.o_custkey
            AND c.c_acctbal < (SELECT AVG(c2.c_acctbal) FROM customer c2)
        )
    GROUP BY
        r.r_name
),
RankedSales AS (
    SELECT
        region_name,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        RegionalSales
)
SELECT
    r.region_name,
    r.total_sales,
    r.order_count,
    CASE 
        WHEN r.order_count > 0 THEN r.total_sales / r.order_count 
        ELSE NULL 
    END AS average_sales_per_order,
    COALESCE(r.sales_rank, 0) AS sales_rank
FROM
    RankedSales r
WHERE
    r.total_sales > (SELECT AVG(total_sales) FROM RegionalSales)
    OR r.region_name LIKE '%east%'
UNION ALL
SELECT
    'Total' AS region_name,
    SUM(total_sales) AS total_sales,
    SUM(order_count) AS order_count,
    CASE 
        WHEN SUM(order_count) > 0 THEN SUM(total_sales) / SUM(order_count) 
        ELSE NULL 
    END AS average_sales_per_order,
    NULL AS sales_rank
FROM
    RankedSales
HAVING 
    COUNT(*) > 1
ORDER BY
    total_sales DESC NULLS LAST;
