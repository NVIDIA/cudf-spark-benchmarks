WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
Top10Orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        r.total_revenue
    FROM 
        RankedOrders r
    JOIN 
        orders o ON r.o_orderkey = o.o_orderkey
    WHERE 
        r.revenue_rank <= 10
)
SELECT 
    cust.c_name,
    cust.c_address,
    t.total_revenue
FROM 
    Top10Orders t
JOIN 
    orders o ON t.o_orderkey = o.o_orderkey
JOIN 
    customer cust ON o.o_custkey = cust.c_custkey
ORDER BY 
    t.total_revenue DESC;
