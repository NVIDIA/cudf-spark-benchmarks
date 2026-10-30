WITH RegionalSales AS (
    SELECT
        r.r_name AS region,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        COUNT(DISTINCT c.c_custkey) AS unique_customers
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
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY
        r.r_name
), RankedSales AS (
    SELECT
        region,
        total_sales,
        total_orders,
        unique_customers,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
        RANK() OVER (ORDER BY total_orders DESC) AS order_rank,
        RANK() OVER (ORDER BY unique_customers DESC) AS customer_rank
    FROM
        RegionalSales
)
SELECT 
    region,
    total_sales,
    total_orders,
    unique_customers,
    sales_rank,
    order_rank,
    customer_rank
FROM 
    RankedSales
WHERE 
    sales_rank <= 5 OR order_rank <= 5 OR customer_rank <= 5
ORDER BY 
    region;