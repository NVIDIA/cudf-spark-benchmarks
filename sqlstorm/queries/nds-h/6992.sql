WITH RegionalSales AS (
    SELECT
        r.r_name AS region,
        SUM(o.o_totalprice) AS total_sales
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
        orders o ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY
        r.r_name
),
SalesRanking AS (
    SELECT
        region,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        RegionalSales
)
SELECT
    s.region,
    s.total_sales,
    s.sales_rank
FROM
    SalesRanking s
WHERE
    s.sales_rank <= 5
ORDER BY
    s.sales_rank;