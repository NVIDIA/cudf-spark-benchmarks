WITH ranked_orders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_nationkey, 
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
top_orders AS (
    SELECT 
        r.o_orderkey, 
        r.o_orderdate, 
        r.o_totalprice, 
        n.n_name AS nation_name 
    FROM 
        ranked_orders r
    JOIN 
        nation n ON r.c_nationkey = n.n_nationkey
    WHERE 
        r.order_rank <= 5
),
total_sales_per_nation AS (
    SELECT 
        n.n_name, 
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_sales
    FROM 
        lineitem lo
    JOIN 
        orders o ON lo.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    t.o_orderkey, 
    t.o_orderdate, 
    t.o_totalprice, 
    ts.n_name AS nation_name, 
    ts.total_sales
FROM 
    top_orders t
JOIN 
    total_sales_per_nation ts ON t.nation_name = ts.n_name
ORDER BY 
    ts.total_sales DESC, t.o_orderdate ASC;
