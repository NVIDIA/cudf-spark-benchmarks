WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
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
        o.o_orderkey, o.o_orderdate, c.c_name, c.c_nationkey
),
TopCustomers AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        COUNT(*) AS customer_count
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON ro.o_orderkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.revenue_rank <= 5
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    region,
    nation,
    customer_count
FROM 
    TopCustomers
ORDER BY 
    customer_count DESC;
