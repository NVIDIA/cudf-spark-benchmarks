
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY 
        o.o_orderkey, c.c_name, o.o_orderdate, c.c_nationkey
),
TopNationRevenue AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT ro.o_orderkey) AS order_count,
        SUM(ro.total_revenue) AS total_nation_revenue
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.c_name = c.c_name
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        ro.revenue_rank <= 5
    GROUP BY 
        n.n_name
)
SELECT 
    n.r_name,
    COALESCE(t.total_nation_revenue, 0) AS total_revenue,
    t.order_count
FROM 
    region n
LEFT JOIN 
    (
        SELECT 
            n.n_regionkey, 
            SUM(t.total_nation_revenue) AS total_nation_revenue,
            SUM(t.order_count) AS order_count
        FROM 
            TopNationRevenue t
        JOIN 
            nation n ON t.n_name = n.n_name
        GROUP BY 
            n.n_regionkey
    ) AS t ON n.r_regionkey = t.n_regionkey
ORDER BY 
    n.r_name;
