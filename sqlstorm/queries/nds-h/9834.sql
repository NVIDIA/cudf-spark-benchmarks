WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_mktsegment, 
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
),
TopCustomerOrders AS (
    SELECT 
        ro.o_orderkey, 
        ro.o_totalprice, 
        ro.o_orderdate, 
        ro.c_mktsegment
    FROM 
        RankedOrders ro
    WHERE 
        ro.rn <= 5
),
OrderLineDetails AS (
    SELECT 
        lo.l_orderkey, 
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS revenue, 
        AVG(lo.l_tax) AS avg_tax
    FROM 
        lineitem lo
    WHERE 
        lo.l_shipdate >= DATE '1996-01-01' 
        AND lo.l_shipdate <= DATE '1996-12-31'
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    tco.o_orderkey, 
    tco.o_totalprice, 
    tco.o_orderdate, 
    tco.c_mktsegment, 
    old.revenue, 
    old.avg_tax
FROM 
    TopCustomerOrders tco
JOIN 
    OrderLineDetails old ON tco.o_orderkey = old.l_orderkey
ORDER BY 
    tco.o_totalprice DESC, 
    tco.o_orderdate ASC;