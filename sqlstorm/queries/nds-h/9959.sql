WITH Revenue AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        c.c_custkey
), RankedRevenue AS (
    SELECT 
        r.c_custkey,
        r.total_revenue,
        ROW_NUMBER() OVER (ORDER BY r.total_revenue DESC) AS revenue_rank
    FROM 
        Revenue r
), TopCustomers AS (
    SELECT 
        n.n_name AS nation,
        COUNT(rc.c_custkey) AS num_customers,
        SUM(rc.total_revenue) AS total_revenue
    FROM 
        RankedRevenue rc
    JOIN 
        customer c ON rc.c_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        rc.revenue_rank <= 10
    GROUP BY 
        n.n_name
)
SELECT 
    t.nation,
    t.num_customers,
    t.total_revenue,
    r.r_name AS region_name
FROM 
    TopCustomers t
JOIN 
    region r ON t.nation = r.r_name
ORDER BY 
    t.total_revenue DESC;