WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
),
TopOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.c_name,
        o.total_revenue
    FROM 
        RankedOrders o
    WHERE 
        o.order_rank <= 10
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.c_name,
    COALESCE(p.p_name, 'N/A') AS part_name,
    ps.ps_supplycost,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_extended_price
FROM 
    TopOrders t
LEFT JOIN 
    lineitem l ON t.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    ps.ps_availqty > 0 
GROUP BY 
    t.o_orderkey, t.o_orderdate, t.c_name, part_name, ps.ps_supplycost
ORDER BY 
    total_extended_price DESC;