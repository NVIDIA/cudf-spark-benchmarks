
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_name,
        SUM(rou.total_revenue) AS annual_revenue
    FROM 
        RankedOrders rou
    JOIN 
        customer c ON rou.c_name = c.c_name
    GROUP BY 
        c.c_name
)
SELECT 
    rc.o_orderkey,
    rc.o_orderdate,
    rc.c_name,
    rc.total_revenue,
    tc.annual_revenue
FROM 
    RankedOrders rc
JOIN 
    TopCustomers tc ON rc.c_name = tc.c_name
WHERE 
    rc.revenue_rank <= 10
ORDER BY 
    rc.o_orderdate, rc.total_revenue DESC;
