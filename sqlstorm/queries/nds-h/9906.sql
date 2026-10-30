WITH SalesSummary AS (
    SELECT 
        c.c_name AS customer_name,
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(o.o_orderkey) AS order_count,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_sale_amount
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-10-01'
    GROUP BY 
        c.c_name, n.n_name
),
RegionRanked AS (
    SELECT 
        customer_name,
        nation_name,
        total_sales,
        order_count,
        avg_sale_amount,
        RANK() OVER (PARTITION BY nation_name ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesSummary
)
SELECT 
    customer_name,
    nation_name,
    total_sales,
    order_count,
    avg_sale_amount,
    sales_rank
FROM 
    RegionRanked
WHERE 
    sales_rank <= 10
ORDER BY 
    nation_name, sales_rank;