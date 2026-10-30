
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
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),

TopRevenueOrders AS (
    SELECT 
        r.o_orderkey,
        r.total_revenue,
        c.c_name,
        s.s_name,
        n.n_name AS supplier_nation,
        r.o_orderdate
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
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        r.revenue_rank <= 10
)

SELECT 
    t.o_orderkey,
    t.total_revenue,
    t.c_name,
    t.s_name,
    t.supplier_nation,
    t.o_orderdate
FROM 
    TopRevenueOrders t
ORDER BY 
    t.total_revenue DESC
LIMIT 10;
