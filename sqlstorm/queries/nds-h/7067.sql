WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' - INTERVAL '1' YEAR
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
TopRevenueOrders AS (
    SELECT 
        r.o_orderkey,
        r.total_revenue,
        r.o_orderstatus
    FROM 
        RankedOrders r
    WHERE 
        r.order_rank <= 10
),
CustomerOrderDetails AS (
    SELECT 
        c.c_name,
        c.c_address,
        c.c_nationkey,
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    cod.c_name,
    cod.c_address,
    cod.c_nationkey,
    tor.total_revenue,
    tor.o_orderstatus
FROM 
    CustomerOrderDetails cod
JOIN 
    TopRevenueOrders tor ON cod.o_orderkey = tor.o_orderkey
ORDER BY 
    tor.total_revenue DESC, cod.c_name;