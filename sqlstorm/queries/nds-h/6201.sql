WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        c.c_name,
        c.c_address,
        c.c_phone,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
nation_summary AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS total_customers,
        SUM(o.o_totalprice) AS total_sales,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_name
)
SELECT 
    rs.c_name,
    rs.o_orderkey,
    rs.o_totalprice,
    ns.n_name AS nation_name,
    ns.total_customers,
    ns.total_sales,
    ns.avg_order_value
FROM 
    ranked_orders rs
JOIN 
    nation_summary ns ON rs.c_name = ns.n_name
WHERE 
    rs.order_rank <= 5
ORDER BY 
    ns.total_sales DESC, 
    rs.o_orderdate ASC;
