WITH SalesData AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        n.n_name AS nation_name,
        r.r_name AS region_name
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
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        c.c_custkey, c.c_name, n.n_name, r.r_name
),
RankedSales AS (
    SELECT 
        c_custkey,
        c_name,
        total_sales,
        nation_name,
        region_name,
        RANK() OVER (PARTITION BY region_name ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    nation_name,
    region_name,
    COUNT(*) AS num_customers,
    AVG(total_sales) AS avg_sales,
    MAX(total_sales) AS max_sales
FROM 
    RankedSales
WHERE 
    sales_rank <= 10
GROUP BY 
    nation_name, region_name
ORDER BY 
    nation_name, region_name;