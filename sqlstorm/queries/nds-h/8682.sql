
WITH SalesData AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, n.n_name
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY nation ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    nation,
    COUNT(c_custkey) AS customer_count,
    SUM(total_sales) AS nation_sales,
    AVG(total_quantity) AS avg_quantity_per_customer
FROM 
    RankedSales
WHERE 
    sales_rank <= 10
GROUP BY 
    nation
ORDER BY 
    nation_sales DESC;
