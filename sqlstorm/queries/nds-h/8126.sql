WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), TopRevenueOrders AS (
    SELECT 
        r.o_orderkey, 
        r.o_orderdate, 
        r.revenue
    FROM 
        RankedOrders r
    WHERE 
        r.order_rank <= 10
)
SELECT 
    r.o_orderkey, 
    r.o_orderdate, 
    r.revenue, 
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
FROM 
    TopRevenueOrders r
JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_custkey = r.o_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    r.o_orderkey, r.o_orderdate, r.revenue, n.n_name, s.s_name
ORDER BY 
    r.revenue DESC, r.o_orderdate ASC;
