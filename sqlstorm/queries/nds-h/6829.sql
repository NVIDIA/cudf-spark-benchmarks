WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
CustomerRevenue AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(ro.revenue) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        RankedOrders ro ON o.o_orderkey = ro.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cr.c_custkey,
    cr.c_name,
    cr.total_revenue,
    CASE 
        WHEN cr.total_revenue > 100000 THEN 'High'
        WHEN cr.total_revenue BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'Low' 
    END AS revenue_category
FROM 
    CustomerRevenue cr
WHERE 
    cr.c_custkey IN (
        SELECT 
            DISTINCT o.o_custkey 
        FROM 
            orders o 
        WHERE 
            o.o_orderstatus = 'O'
    )
ORDER BY 
    cr.total_revenue DESC;