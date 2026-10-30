WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderstatus, 
        c.c_name, 
        c.c_acctbal, 
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey, 
        ro.o_orderdate, 
        ro.o_totalprice, 
        ro.c_name, 
        ro.c_acctbal
    FROM 
        RankedOrders ro
    WHERE 
        ro.rnk <= 10
),
OrderDetails AS (
    SELECT 
        hvo.o_orderkey, 
        SUM(ROUND(l.l_extendedprice * (1 - l.l_discount), 2)) AS total_revenue
    FROM 
        HighValueOrders hvo
    JOIN 
        lineitem l ON hvo.o_orderkey = l.l_orderkey
    GROUP BY 
        hvo.o_orderkey
)
SELECT 
    hvo.o_orderkey, 
    hvo.o_orderdate, 
    hvo.c_name, 
    hvo.c_acctbal, 
    od.total_revenue
FROM 
    HighValueOrders hvo
JOIN 
    OrderDetails od ON hvo.o_orderkey = od.o_orderkey
ORDER BY 
    od.total_revenue DESC;