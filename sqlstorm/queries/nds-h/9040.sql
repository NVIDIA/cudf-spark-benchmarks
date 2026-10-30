WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_name, c.c_nationkey
),
TopCustomers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        COUNT(ro.o_orderkey) AS order_count,
        SUM(ro.total_revenue) AS total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.c_name = c.c_name
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.revenue_rank <= 10
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    region_name,
    nation_name,
    order_count,
    total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS overall_rank
FROM 
    TopCustomers
ORDER BY 
    overall_rank;
