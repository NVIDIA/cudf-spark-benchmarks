WITH TotalSales AS (
    SELECT
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM
        lineitem l
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY
        n.n_name
),
SalesRank AS (
    SELECT
        nation_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        TotalSales
)
SELECT
    s.nation_name,
    s.total_sales,
    r.sales_rank,
    (SELECT AVG(total_sales) FROM TotalSales) AS avg_sales
FROM
    SalesRank r
JOIN
    TotalSales s ON s.nation_name = r.nation_name
WHERE
    r.sales_rank <= 5
ORDER BY
    r.sales_rank;
