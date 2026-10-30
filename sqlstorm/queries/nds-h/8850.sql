WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_order
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l.l_shipdate >= DATE '1997-01-01'
        AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey
),
TopRevenueOrders AS (
    SELECT 
        r.o_orderkey, 
        r.total_revenue
    FROM 
        RankedOrders r
    WHERE 
        r.rank_order <= 10
)
SELECT 
    o.o_orderkey, 
    c.c_name, 
    r.r_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT l.l_partkey) AS unique_parts_supplied
FROM 
    TopRevenueOrders tro
JOIN 
    orders o ON tro.o_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    o.o_orderkey, c.c_name, r.r_name
ORDER BY 
    revenue DESC;