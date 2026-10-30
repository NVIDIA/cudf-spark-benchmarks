WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders AS o 
    JOIN 
        lineitem AS l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.total_revenue
    FROM 
        RankedOrders AS r
    WHERE 
        r.rn = 1
    ORDER BY 
        r.total_revenue DESC
    LIMIT 10
)
SELECT 
    o.o_orderkey AS order_id,
    o.o_orderdate AS order_date,
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
FROM 
    TopRevenueOrders AS tro
JOIN 
    orders AS o ON o.o_orderkey = tro.o_orderkey
JOIN 
    lineitem AS l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp AS ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
JOIN 
    part AS p ON l.l_partkey = p.p_partkey
JOIN 
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
GROUP BY 
    o.o_orderkey, o.o_orderdate, p.p_name, s.s_name
ORDER BY 
    order_total DESC;