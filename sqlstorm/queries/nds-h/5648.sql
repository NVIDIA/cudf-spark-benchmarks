WITH RegionalSales AS (
    SELECT
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        COUNT(DISTINCT c.c_custkey) AS total_customers
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
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderdate >= DATE '1994-01-01'
        AND o.o_orderdate < DATE '1995-01-01'
        AND c.c_mktsegment = 'BUILDING'
    GROUP BY
        r.r_name
)
SELECT
    region_name,
    total_sales,
    total_orders,
    total_customers,
    total_sales / NULLIF(total_orders, 0) AS avg_sales_per_order,
    total_sales / NULLIF(total_customers, 0) AS avg_sales_per_customer
FROM
    RegionalSales
ORDER BY
    total_sales DESC
LIMIT 10;
