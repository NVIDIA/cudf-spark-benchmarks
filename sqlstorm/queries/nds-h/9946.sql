WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name AS customer_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name, c.c_nationkey
),
TopCustomers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        SUM(ro.total_revenue) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(ro.total_revenue) DESC) AS region_rank
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.customer_name = c.c_name
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name, n.n_name
)
SELECT 
    region_name, 
    nation_name, 
    total_revenue
FROM 
    TopCustomers
WHERE 
    region_rank <= 5
ORDER BY 
    region_name, total_revenue DESC;