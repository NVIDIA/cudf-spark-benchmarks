WITH  RegionalSales AS (
    SELECT
        n.n_name AS nation,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM
        nation n
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY
        n.n_name, n.n_nationkey
),
TopNations AS (
    SELECT
        nation,
        total_sales
    FROM
        RegionalSales
    WHERE
        sales_rank <= 5
),
NationComments AS (
    SELECT
        n.n_name AS nation,
        n.n_comment AS comments,
        t.total_sales
    FROM
        nation n
    LEFT JOIN
        TopNations t ON n.n_name = t.nation
)
SELECT
    n.nation,
    COALESCE(n.comments, 'No sales') AS comments,
    COALESCE(n.total_sales, 0.00) AS total_sales,
    CASE
        WHEN n.total_sales IS NULL THEN 'No Sales'
        WHEN n.total_sales > 50000 THEN 'High Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM
    NationComments n
UNION ALL
SELECT
    r.r_name AS region,
    'Total Sales in Region' AS comments,
    SUM(t.total_sales) AS total_sales,
    CASE
        WHEN SUM(t.total_sales) IS NULL THEN 'No Sales'
        WHEN SUM(t.total_sales) > 250000 THEN 'High Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM
    region r
LEFT JOIN
    NationComments n ON r.r_name = n.nation
LEFT JOIN
    TopNations t ON n.total_sales = t.total_sales
GROUP BY
    r.r_name
ORDER BY
    total_sales DESC;
