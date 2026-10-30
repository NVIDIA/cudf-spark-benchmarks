
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus
),
TopRevenueOrders AS (
    SELECT 
        rank.o_orderkey,
        rank.o_orderdate,
        rank.o_totalprice,
        rank.o_orderstatus,
        rank.total_revenue
    FROM 
        RankedOrders rank
    WHERE 
        rank.revenue_rank <= 10
)
SELECT 
    c.c_name,
    c.c_acctbal,
    c.c_mktsegment,
    tor.o_orderkey,
    tor.o_orderdate,
    tor.o_totalprice
FROM 
    TopRevenueOrders tor
JOIN 
    customer c ON tor.o_orderkey = c.c_custkey
WHERE 
    c.c_acctbal > 50000
ORDER BY 
    tor.o_orderdate DESC, tor.o_totalprice DESC;
