WITH RegionalSales AS (
    SELECT 
        r.r_regionkey,
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT c.c_custkey) AS unique_customers,
        COUNT(DISTINCT o.o_orderkey) AS order_count
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
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY 
        r.r_regionkey, r.r_name
)

SELECT 
    region_name,
    total_sales,
    unique_customers,
    order_count,
    total_sales / NULLIF(unique_customers, 0) AS avg_sales_per_customer,
    total_sales / NULLIF(order_count, 0) AS avg_sales_per_order
FROM 
    RegionalSales
ORDER BY 
    total_sales DESC
LIMIT 10;