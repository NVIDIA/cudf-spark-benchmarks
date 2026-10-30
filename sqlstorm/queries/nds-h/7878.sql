WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
top_orders AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        COUNT(ro.o_orderkey) AS total_orders,
        AVG(ro.o_totalprice) AS avg_order_value
    FROM 
        ranked_orders ro
    JOIN 
        customer c ON ro.c_name = c.c_name
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.order_rank <= 10
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    region_name,
    nation_name,
    total_orders,
    ROUND(avg_order_value, 2) AS average_order_value,
    RANK() OVER (ORDER BY total_orders DESC) AS order_rank
FROM 
    top_orders
ORDER BY 
    total_orders DESC, nation_name;