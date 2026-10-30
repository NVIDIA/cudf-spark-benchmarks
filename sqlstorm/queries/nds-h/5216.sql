WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_order
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
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
        ro.rank_order <= 10
), 
OrderDetails AS (
    SELECT 
        hvo.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(DISTINCT li.l_partkey) AS num_items,
        AVG(li.l_quantity) AS avg_quantity
    FROM 
        HighValueOrders hvo
    JOIN 
        lineitem li ON hvo.o_orderkey = li.l_orderkey
    GROUP BY 
        hvo.o_orderkey
)
SELECT 
    hvo.o_orderkey,
    hvo.o_orderdate,
    hvo.o_totalprice,
    hvo.c_name,
    hvo.c_acctbal,
    od.total_revenue,
    od.num_items,
    od.avg_quantity
FROM 
    HighValueOrders hvo
JOIN 
    OrderDetails od ON hvo.o_orderkey = od.o_orderkey
ORDER BY 
    hvo.o_orderdate DESC, hvo.o_totalprice DESC;
