WITH  sales_data AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate <= DATE '1996-12-31'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
ranked_sales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        sd.o_orderkey,
        sd.o_orderdate,
        sd.total_sales,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        sales_data sd
    JOIN 
        customer c ON sd.c_custkey = c.c_custkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT rs.c_custkey) AS high_value_customers,
    SUM(rs.total_sales) AS total_revenue
FROM 
    ranked_sales rs
JOIN 
    nation n ON rs.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    rs.sales_rank <= 10
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC;