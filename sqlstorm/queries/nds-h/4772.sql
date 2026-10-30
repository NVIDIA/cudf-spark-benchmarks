WITH SupplierSales AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-10-01'
    GROUP BY
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM
        supplier s
    JOIN
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
)
SELECT
    r.r_name,
    COUNT(DISTINCT rs.s_suppkey) AS top_suppliers_count,
    AVG(rs.total_sales) AS avg_total_sales
FROM
    rankedsuppliers rs
JOIN
    supplier s ON rs.s_suppkey = s.s_suppkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    rs.sales_rank <= 10
GROUP BY
    r.r_name
ORDER BY
    avg_total_sales DESC
LIMIT 5;