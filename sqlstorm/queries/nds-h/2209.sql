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
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT
        sss.*,
        RANK() OVER (ORDER BY sss.total_sales DESC) AS sales_rank
    FROM
        SupplierSales sss
),
FilteredSuppliers AS (
    SELECT
        rs.s_suppkey,
        rs.s_name,
        rs.total_sales,
        rs.order_count,
        CASE 
            WHEN rs.order_count > 10 THEN 'High'
            WHEN rs.order_count BETWEEN 5 AND 10 THEN 'Medium'
            ELSE 'Low'
        END AS order_category
    FROM
        RankedSuppliers rs
    WHERE
        rs.total_sales > (SELECT AVG(total_sales) FROM SupplierSales) 
)
SELECT
    p.p_name,
    fs.s_name,
    fs.total_sales,
    fs.order_category,
    r.r_name,
    n.n_name
FROM
    FilteredSuppliers fs
LEFT JOIN
    partsupp ps ON fs.s_suppkey = ps.ps_suppkey
LEFT JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    supplier s ON fs.s_suppkey = s.s_suppkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    p.p_retailprice >= 100.00
    AND (p.p_comment IS NULL OR p.p_comment LIKE '%premium%')
ORDER BY
    fs.total_sales DESC, fs.order_category ASC;