WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
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
        ro.order_rank <= 10
),
OrderDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        SUM(l.l_tax) AS total_tax,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        lineitem l
    JOIN 
        HighValueOrders hvo ON l.l_orderkey = hvo.o_orderkey
    GROUP BY 
        l.l_orderkey
)
SELECT 
    hvo.o_orderkey,
    hvo.o_orderdate,
    hvo.c_name,
    hvo.c_acctbal,
    od.total_sales,
    od.total_tax,
    od.total_quantity
FROM 
    HighValueOrders hvo
JOIN 
    OrderDetails od ON hvo.o_orderkey = od.l_orderkey
ORDER BY 
    hvo.o_orderdate, hvo.o_orderkey;