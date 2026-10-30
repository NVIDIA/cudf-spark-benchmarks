WITH total_sales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS sales
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1995-01-01' AND 
        l.l_shipdate < DATE '1996-01-01'
    GROUP BY 
        l.l_orderkey
),
customer_sales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(ts.sales) AS total_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        total_sales ts ON o.o_orderkey = ts.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
ranked_customers AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
)
SELECT 
    rc.c_custkey,
    rc.c_name,
    rc.total_sales
FROM 
    ranked_customers rc
WHERE 
    rc.sales_rank <= 10
ORDER BY 
    rc.total_sales DESC;
