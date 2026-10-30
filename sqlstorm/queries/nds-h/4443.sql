WITH SupplierSales AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_nationkey, SUM(ss.total_sales) AS total_sales_by_nation
    FROM SupplierSales ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE ss.sales_rank <= 3
    GROUP BY s.s_nationkey
),
NationSales AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        COALESCE(ts.total_sales_by_nation, 0) AS total_sales_by_nation
    FROM
        nation n
    LEFT JOIN
        TopSuppliers ts ON n.n_nationkey = ts.s_nationkey
)
SELECT
    r.r_name,
    SUM(ns.total_sales_by_nation) AS total_sales_in_region
FROM
    region r
JOIN
    nation n ON r.r_regionkey = n.n_regionkey
JOIN
    NationSales ns ON n.n_nationkey = ns.n_nationkey
GROUP BY
    r.r_name
HAVING
    SUM(ns.total_sales_by_nation) > 0
ORDER BY
    total_sales_in_region DESC;
