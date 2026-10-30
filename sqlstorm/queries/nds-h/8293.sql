WITH sales_data AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        o.o_orderdate,
        c.c_nationkey,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
        AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        l.l_orderkey, o.o_orderdate, c.c_nationkey, n.n_name, r.r_name
),
ranked_sales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY nation_name ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_data
)
SELECT 
    nation_name,
    SUM(total_sales) AS total_sales_sum,
    AVG(total_sales) AS average_sales,
    COUNT(DISTINCT l_orderkey) AS total_orders,
    MAX(total_sales) AS max_sales_order
FROM 
    ranked_sales
WHERE 
    sales_rank <= 5
GROUP BY 
    nation_name
ORDER BY 
    total_sales_sum DESC;