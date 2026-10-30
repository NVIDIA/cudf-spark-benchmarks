WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
RecentOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        n.n_name,
        n.n_regionkey
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON ro.c_nationkey = n.n_nationkey
    WHERE 
        ro.rn <= 10
),
OrderLineItems AS (
    SELECT 
        r.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        RecentOrders r
    JOIN 
        lineitem l ON r.o_orderkey = l.l_orderkey
    GROUP BY 
        r.o_orderkey
),
NationRevenue AS (
    SELECT 
        n.n_name,
        SUM(oli.revenue) AS total_revenue
    FROM 
        OrderLineItems oli
    JOIN 
        RecentOrders r ON oli.o_orderkey = r.o_orderkey
    JOIN 
        nation n ON r.n_regionkey = n.n_regionkey
    GROUP BY 
        n.n_name
)
SELECT 
    n.n_name,
    nr.total_revenue
FROM 
    NationRevenue nr
JOIN 
    nation n ON nr.n_name = n.n_name
ORDER BY 
    nr.total_revenue DESC
LIMIT 5;
