
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
),
TopOrders AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        COUNT(*) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        RankedOrders o
    JOIN 
        customer c ON o.c_name = c.c_name
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.order_rank <= 10
    GROUP BY 
        r.r_name, 
        n.n_name
)
SELECT 
    region,
    nation,
    total_orders,
    avg_order_value,
    RANK() OVER (ORDER BY total_orders DESC) AS rank_by_orders
FROM 
    TopOrders
ORDER BY 
    total_orders DESC, 
    avg_order_value DESC;
