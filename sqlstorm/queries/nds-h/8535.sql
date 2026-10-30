
WITH sales_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01' 
        AND p.p_size >= 10
    GROUP BY 
        c.c_custkey, c.c_name, n.n_name
),
ranked_sales AS (
    SELECT 
        cust.c_custkey,
        cust.c_name,
        cust.nation,
        cust.total_sales,
        cust.order_count,
        DENSE_RANK() OVER (PARTITION BY cust.nation ORDER BY cust.total_sales DESC) AS sales_rank
    FROM 
        sales_summary cust
)
SELECT 
    r.nation,
    COUNT(*) AS customer_count,
    AVG(r.total_sales) AS average_sales,
    MAX(r.order_count) AS max_orders,
    MIN(r.order_count) AS min_orders
FROM 
    ranked_sales r
WHERE 
    r.sales_rank <= 10
GROUP BY 
    r.nation
ORDER BY 
    average_sales DESC;
