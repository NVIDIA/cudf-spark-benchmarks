WITH SalesData AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, n.n_name
), RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY nation_name ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    nation_name,
    COUNT(c_custkey) AS total_customers,
    SUM(total_sales) AS total_sales_by_nation,
    AVG(total_sales) AS avg_sales_per_customer,
    MAX(order_count) AS max_orders_per_customer
FROM 
    RankedSales
WHERE 
    sales_rank <= 10
GROUP BY 
    nation_name
ORDER BY 
    total_sales_by_nation DESC;