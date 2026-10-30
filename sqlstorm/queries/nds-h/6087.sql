
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_nationkey,
        c.c_mktsegment,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1994-01-01' AND 
        o.o_orderdate < DATE '1995-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_nationkey, c.c_mktsegment
),
TopCustomers AS (
    SELECT 
        rc.c_nationkey AS n_name,
        rc.c_mktsegment,
        rc.total_revenue,
        rc.revenue_rank
    FROM 
        RankedOrders rc
    WHERE 
        rc.revenue_rank <= 10
)
SELECT 
    tc.n_name,
    tc.c_mktsegment,
    SUM(tc.total_revenue) AS sum_total_revenue
FROM 
    TopCustomers tc
GROUP BY 
    tc.n_name, tc.c_mktsegment
ORDER BY 
    sum_total_revenue DESC;
