
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus, 
        o.o_totalprice, 
        o.o_orderdate, 
        o.o_orderpriority, 
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
TopNations AS (
    SELECT 
        n.n_nationkey, 
        n.n_name,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue
    FROM 
        lineitem lo
    JOIN 
        RankedOrders ro ON lo.l_orderkey = ro.o_orderkey
    JOIN 
        nation n ON ro.c_nationkey = n.n_nationkey
    WHERE 
        ro.rn <= 10
    GROUP BY 
        n.n_nationkey, n.n_name
),
AvgRevenue AS (
    SELECT 
        AVG(total_revenue) AS avg_revenue
    FROM 
        TopNations
)
SELECT 
    tn.n_name, 
    tn.total_revenue,
    ar.avg_revenue,
    CASE 
        WHEN tn.total_revenue > ar.avg_revenue THEN 'Above Average'
        ELSE 'Below Average'
    END AS revenue_comparison
FROM 
    TopNations tn
CROSS JOIN 
    AvgRevenue ar
ORDER BY 
    tn.total_revenue DESC;
