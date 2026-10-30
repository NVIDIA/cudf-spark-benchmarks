WITH sales_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        MIN(o.o_orderdate) AS first_order_date,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
ranked_sales AS (
    SELECT 
        s.*,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary s
)
SELECT 
    r.r_name AS region_name,
    COUNT(rs.c_custkey) AS customer_count,
    AVG(rs.total_sales) AS avg_sales,
    SUM(rs.total_sales) AS total_sales_value
FROM 
    ranked_sales rs
JOIN 
    nation n ON rs.c_custkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    rs.sales_rank <= 10
GROUP BY 
    r.r_name
ORDER BY 
    total_sales_value DESC;
