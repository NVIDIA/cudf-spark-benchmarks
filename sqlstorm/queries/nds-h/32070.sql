
WITH  CTE_SupplierSales AS (
    SELECT
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY
        s.s_suppkey
),
CTE_NationRegion AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        r.r_name,
        SUM(ps.ps_availqty) AS total_availqty
    FROM
        nation n
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        n.n_nationkey, n.n_name, r.r_name
)
SELECT
    avail.n_name AS nation_name,
    cr.r_name AS region_name,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(avail.total_availqty, 0) AS total_availqty,
    (SELECT COUNT(*) FROM orders o WHERE o.o_orderstatus = 'F') AS finished_order_count
FROM
    CTE_NationRegion avail
FULL OUTER JOIN CTE_SupplierSales s ON avail.n_nationkey = s.s_suppkey
JOIN region cr ON avail.r_name = cr.r_name
WHERE
    (COALESCE(s.total_sales, 0) > 10000 OR COALESCE(avail.total_availqty, 0) > 0)
ORDER BY
    total_sales DESC,
    nation_name ASC;
