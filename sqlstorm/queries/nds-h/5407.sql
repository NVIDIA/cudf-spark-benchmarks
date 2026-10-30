
WITH RegionalSales AS (
    SELECT 
        r.r_name AS region,
        SUM(ol.l_extendedprice * (1 - ol.l_discount)) AS total_sales
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
        lineitem ol ON p.p_partkey = ol.l_partkey
    GROUP BY 
        r.r_name
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        SUM(ol.l_extendedprice * (1 - ol.l_discount)) AS customer_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem ol ON o.o_orderkey = ol.l_orderkey
    GROUP BY 
        c.c_custkey
),
RankedSales AS (
    SELECT 
        c.c_custkey,
        cs.customer_sales,
        RANK() OVER (ORDER BY cs.customer_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_custkey = c.c_custkey
)
SELECT 
    rs.region,
    COUNT(DISTINCT r.c_custkey) AS total_customers,
    SUM(cs.customer_sales) AS total_sales,
    AVG(cs.customer_sales) AS avg_sales_per_customer
FROM 
    RegionalSales rs
JOIN 
    RankedSales r ON rs.total_sales = r.customer_sales
JOIN 
    CustomerSales cs ON r.c_custkey = cs.c_custkey
GROUP BY 
    rs.region
ORDER BY 
    total_sales DESC;
