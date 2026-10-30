WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' 
        AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), CustomerStats AS (
    SELECT 
        c.c_name,
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(ro.total_revenue) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        RankedOrders ro ON o.o_orderkey = ro.o_orderkey
    GROUP BY 
        c.c_name, c.c_nationkey
), NationRevenue AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(cs.total_revenue) AS nation_total_revenue,
        AVG(cs.total_orders) AS avg_orders_per_customer
    FROM 
        nation n
    JOIN 
        CustomerStats cs ON n.n_nationkey = cs.c_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    nr.nation_name,
    nr.nation_total_revenue,
    nr.avg_orders_per_customer,
    r.r_name AS region_name
FROM 
    NationRevenue nr
JOIN 
    region r ON nr.nation_name LIKE '%' || r.r_name || '%'
ORDER BY 
    nr.nation_total_revenue DESC, nr.nation_name
LIMIT 10;