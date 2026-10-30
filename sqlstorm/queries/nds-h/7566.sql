WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        r.r_name AS region_name,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate <= DATE '1996-12-31'
),
TopOrders AS (
    SELECT 
        order_rank,
        o_orderkey,
        o_orderdate,
        o_totalprice,
        c_name,
        region_name
    FROM 
        RankedOrders
    WHERE 
        order_rank <= 10
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    o.c_name,
    o.region_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(l.l_orderkey) AS item_count
FROM 
    TopOrders o
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
GROUP BY 
    o.o_orderkey, o.o_orderdate, o.o_totalprice, o.c_name, o.region_name
ORDER BY 
    total_revenue DESC;
