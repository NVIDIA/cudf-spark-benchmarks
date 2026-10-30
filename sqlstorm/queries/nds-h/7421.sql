WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderpriority, 
        c.c_name, 
        c.c_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
),
HighValueOrders AS (
    SELECT 
        r.o_orderkey, 
        r.o_orderstatus, 
        r.o_totalprice, 
        r.o_orderdate, 
        r.c_name, 
        r.c_acctbal
    FROM 
        RankedOrders r
    WHERE 
        r.rn <= 10
),
OrderDetails AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        HighValueOrders hvo ON l.l_orderkey = hvo.o_orderkey
    GROUP BY 
        l.l_orderkey
)
SELECT 
    hvo.o_orderkey, 
    hvo.o_orderstatus, 
    hvo.o_totalprice, 
    hvo.o_orderdate, 
    hvo.c_name, 
    hvo.c_acctbal, 
    od.total_revenue
FROM 
    HighValueOrders hvo
LEFT JOIN 
    OrderDetails od ON hvo.o_orderkey = od.l_orderkey
ORDER BY 
    hvo.o_orderkey;