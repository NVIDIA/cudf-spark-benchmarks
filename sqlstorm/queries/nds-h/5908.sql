WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        c.c_name AS customer_name,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND 
        o.o_orderdate < DATE '1997-12-31'
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.customer_name,
        ro.o_totalprice,
        ro.o_orderstatus,
        ro.o_orderdate
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 5
),
OrderDetails AS (
    SELECT 
        hvo.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linenumber) AS item_count
    FROM 
        HighValueOrders hvo
    JOIN 
        lineitem l ON hvo.o_orderkey = l.l_orderkey
    GROUP BY 
        hvo.o_orderkey
)
SELECT 
    hvo.o_orderkey,
    hvo.customer_name,
    hvo.o_totalprice,
    od.total_revenue,
    od.item_count
FROM 
    HighValueOrders hvo
JOIN 
    OrderDetails od ON hvo.o_orderkey = od.o_orderkey
ORDER BY 
    hvo.o_totalprice DESC, 
    od.total_revenue DESC
LIMIT 10;