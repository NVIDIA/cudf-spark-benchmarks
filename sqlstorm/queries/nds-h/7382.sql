WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
),
TopNRevenue AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.c_name,
        total_revenue
    FROM 
        RankedOrders o
    WHERE 
        revenue_rank <= 5
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.c_name,
    t.total_revenue,
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    ps.ps_supplycost
FROM 
    TopNRevenue t
JOIN 
    lineitem l ON t.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    t.total_revenue > 10000
ORDER BY 
    t.total_revenue DESC, t.o_orderdate ASC;