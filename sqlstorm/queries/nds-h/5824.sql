WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate <= DATE '1996-12-31'
),
TopCustomers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        cu.c_name AS customer_name,
        ro.o_orderkey,
        ro.o_totalprice
    FROM 
        RankedOrders ro
    JOIN 
        customer cu ON cu.c_custkey = ro.o_orderkey
    JOIN 
        nation n ON cu.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.order_rank <= 5
)
SELECT 
    t.region_name,
    t.nation_name,
    t.customer_name,
    SUM(t.o_totalprice) AS total_spent,
    COUNT(t.o_orderkey) AS total_orders
FROM 
    TopCustomers t
GROUP BY 
    t.region_name, t.nation_name, t.customer_name
ORDER BY 
    total_spent DESC
LIMIT 10;