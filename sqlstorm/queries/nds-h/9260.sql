
WITH sales_data AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_shipdate >= '1997-01-01'
        AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        l.l_orderkey
),
customer_sales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(sd.total_sales) AS total_sales,
        SUM(sd.order_count) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        sales_data sd ON o.o_orderkey = sd.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
ranked_customers AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
)
SELECT 
    rc.c_custkey,
    rc.c_name,
    rc.total_sales,
    rc.order_count,
    rc.sales_rank
FROM 
    ranked_customers rc
WHERE 
    rc.sales_rank <= 10
ORDER BY 
    rc.total_sales DESC;
