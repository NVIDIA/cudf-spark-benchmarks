WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
),
TopRevenueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        c.c_name, 
        r.revenue
    FROM 
        RankedOrders r
    JOIN 
        orders o ON r.o_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        r.revenue_rank <= 10
)
SELECT 
    tr.o_orderkey, 
    tr.o_orderdate, 
    tr.c_name, 
    tr.revenue, 
    COUNT(li.l_linenumber) AS lineitem_count,
    SUM(li.l_quantity) AS total_quantity,
    AVG(li.l_extendedprice) AS avg_extended_price
FROM 
    TopRevenueOrders tr
JOIN 
    lineitem li ON tr.o_orderkey = li.l_orderkey
GROUP BY 
    tr.o_orderkey, tr.o_orderdate, tr.c_name, tr.revenue
ORDER BY 
    tr.revenue DESC;