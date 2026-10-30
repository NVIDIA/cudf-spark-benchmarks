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
    GROUP BY
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        ss.order_count,
        ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM
        supplier s
    JOIN
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE
        ss.total_sales > 1000
),
RegionsWithCustomers AS (
    SELECT
        r.r_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM
        region r
    JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY
        r.r_name
),
HighValueRegions AS (
    SELECT
        r.r_name,
        rc.customer_count,
        CASE
            WHEN rc.customer_count > 50 THEN 'High'
            ELSE 'Low'
        END AS region_value
    FROM
        RegionsWithCustomers rc
    JOIN
        region r ON rc.customer_count > 0
)
SELECT
    ts.s_name,
    ts.total_sales,
    hvr.r_name,
    hvr.region_value,
    COALESCE(NULLIF(ts.order_count, 0), 1) AS safe_order_count  
FROM
    TopSuppliers ts
FULL OUTER JOIN
    HighValueRegions hvr ON ts.s_suppkey = hvr.customer_count  
WHERE
    hvr.region_value = 'High'
    OR ts.total_sales > 5000
ORDER BY
    ts.total_sales DESC, hvr.r_name ASC;