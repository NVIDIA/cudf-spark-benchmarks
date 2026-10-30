WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rn
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
),
NationOrderSummary AS (
    SELECT
        n.n_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        nation n
    LEFT JOIN
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        n.n_name
),
SupplierSales AS (
    SELECT
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY
        s.s_suppkey
)
SELECT
    r.r_name,
    n.total_orders,
    COALESCE(n.total_revenue, 0) AS total_revenue,
    ss.total_sales,
    CASE 
        WHEN ss.total_sales IS NULL THEN 'No Sales Data'
        ELSE 'Sales Available'
    END AS sales_status,
    CONCAT('Supplier ', s.s_name, ' from region ', r.r_name) AS supplier_info
FROM
    region r
LEFT JOIN
    NationOrderSummary n ON r.r_name = n.n_name
LEFT JOIN 
    RankedSuppliers rs ON rs.rn = 1
LEFT JOIN 
    SupplierSales ss ON ss.s_suppkey = rs.s_suppkey
LEFT JOIN 
    supplier s ON s.s_suppkey = ss.s_suppkey
WHERE
    (n.total_orders > 5 OR ss.total_sales IS NOT NULL)
    AND rs.s_name IS NOT NULL
    AND (n.n_name IS NOT NULL OR r.r_name IS NULL)
ORDER BY
    r.r_name, n.total_orders DESC;
