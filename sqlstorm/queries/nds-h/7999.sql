
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
        o.o_orderdate >= DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.total_revenue
    FROM 
        RankedOrders ro
    WHERE 
        ro.revenue_rank <= 10
),
SupplierPartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        s.s_suppkey, 
        s.s_name, 
        ps.ps_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    t.o_orderkey, 
    t.o_orderdate, 
    sp.p_partkey, 
    sp.p_name, 
    sp.s_suppkey, 
    sp.s_name, 
    sp.ps_supplycost, 
    t.total_revenue
FROM 
    TopRevenueOrders t
JOIN 
    lineitem l ON t.o_orderkey = l.l_orderkey
JOIN 
    SupplierPartDetails sp ON l.l_partkey = sp.p_partkey
ORDER BY 
    t.total_revenue DESC
LIMIT 10;
