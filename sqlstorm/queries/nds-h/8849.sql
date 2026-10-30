WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate <= DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT 
        r.o_orderkey,
        r.total_revenue,
        r.o_orderdate,
        c.c_name,
        s.s_name,
        p.p_name 
    FROM 
        RankedOrders r
    JOIN 
        orders o ON r.o_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    WHERE 
        r.revenue_rank <= 10
)
SELECT 
    o_orderkey,
    total_revenue,
    o_orderdate,
    c_name,
    s_name,
    p_name,
    ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS overall_rank
FROM 
    TopRevenueOrders
ORDER BY 
    total_revenue DESC;
