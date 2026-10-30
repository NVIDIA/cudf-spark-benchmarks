
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE('1994-01-01') AND o.o_orderdate < DATE('1995-01-01')
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
TopRevenueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        r.total_revenue
    FROM 
        RankedOrders r
    JOIN 
        orders o ON r.o_orderkey = o.o_orderkey
    WHERE 
        r.rank <= 10
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_orderstatus,
    t.total_revenue,
    s.s_name AS supplier_name,
    s.s_address AS supplier_address,
    c.c_name AS customer_name,
    c.c_address AS customer_address
FROM 
    TopRevenueOrders t
JOIN 
    orders o ON t.o_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
ORDER BY 
    t.total_revenue DESC;
