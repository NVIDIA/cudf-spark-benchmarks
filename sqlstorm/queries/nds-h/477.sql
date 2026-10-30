
WITH RegionalSales AS (
    SELECT
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM
        region r
    JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
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
    r.r_name AS region_name,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COALESCE(rs.order_count, 0) AS order_count,
    CASE
        WHEN rs.sales_rank IS NOT NULL THEN rs.sales_rank
        ELSE (SELECT COUNT(*) FROM RankedSales) + 1
    END AS sales_rank
FROM
    region r
LEFT JOIN
    RankedSales rs ON r.r_name = rs.region_name
WHERE
    r.r_name LIKE 'N%'
ORDER BY
    total_sales DESC NULLS LAST;
