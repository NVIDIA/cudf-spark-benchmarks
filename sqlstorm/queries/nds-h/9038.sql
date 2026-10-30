WITH RankedOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND 
        o.o_orderdate < '1997-12-31'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(ro.total_revenue) AS total_revenue
    FROM 
        customer c
    JOIN 
        RankedOrders ro ON c.c_custkey = ro.c_custkey
    WHERE 
        ro.revenue_rank <= 5
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    tc.total_revenue,
    r.r_name AS region_name
FROM 
    TopCustomers tc
JOIN 
    supplier s ON s.s_nationkey = (SELECT n.n_nationkey 
                                     FROM nation n 
                                     WHERE n.n_name = 'USA')
JOIN 
    region r ON s.s_nationkey = r.r_regionkey
ORDER BY 
    tc.total_revenue DESC;