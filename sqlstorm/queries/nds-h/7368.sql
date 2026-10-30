
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name, c.c_nationkey
),
top_customers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        rc.c_name AS cust_name,
        rc.total_revenue
    FROM 
        ranked_orders rc
    JOIN 
        customer c ON rc.c_name = c.c_name
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rc.rank <= 10
)
SELECT 
    region_name,
    nation_name,
    COUNT(cust_name) AS top_customer_count,
    SUM(total_revenue) AS total_revenue_sum
FROM 
    top_customers
GROUP BY 
    region_name, nation_name
ORDER BY 
    region_name, total_revenue_sum DESC;
