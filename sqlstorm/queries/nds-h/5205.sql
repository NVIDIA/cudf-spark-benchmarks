
WITH TotalSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        n.n_name AS nation
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
    GROUP BY 
        c.c_custkey, c.c_name, n.n_name
),
RankedSales AS (
    SELECT 
        nation,
        c_name,
        total_sales,
        RANK() OVER (PARTITION BY nation ORDER BY total_sales DESC) AS sales_rank
    FROM 
        TotalSales
)
SELECT 
    nation,
    ARRAY_AGG(c_name) AS top_customers
FROM 
    RankedSales
WHERE 
    sales_rank <= 3
GROUP BY 
    nation
ORDER BY 
    nation;
