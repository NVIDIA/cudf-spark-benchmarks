WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_orderpriority,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate <= DATE '1997-12-31'
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.o_orderstatus,
        ro.o_orderpriority
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 100
),
CustomerSpendings AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    cs.total_spent,
    hvo.o_orderkey,
    hvo.o_orderdate,
    hvo.o_totalprice
FROM 
    CustomerSpendings cs
JOIN 
    HighValueOrders hvo ON cs.total_spent > 5000
ORDER BY 
    cs.total_spent DESC, hvo.o_orderdate ASC
LIMIT 50;