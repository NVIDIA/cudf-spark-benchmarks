WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
),
OrderLineItems AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS revenue,
        COUNT(*) AS item_count,
        SUM(lo.l_quantity) AS total_quantity
    FROM 
        lineitem lo
    JOIN 
        RankedOrders ro ON lo.l_orderkey = ro.o_orderkey
    WHERE 
        lo.l_shipmode IN ('AIR', 'GROUND')
    GROUP BY 
        lo.l_orderkey
),
TopCustomers AS (
    SELECT 
        ro.c_name,
        SUM(ol.revenue) AS total_revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(ol.revenue) DESC) AS customer_rank
    FROM 
        RankedOrders ro
    JOIN 
        OrderLineItems ol ON ro.o_orderkey = ol.l_orderkey
    GROUP BY 
        ro.c_name
)
SELECT 
    tc.c_name, 
    tc.total_revenue, 
    tc.customer_rank
FROM 
    TopCustomers tc
WHERE 
    tc.customer_rank <= 10
ORDER BY 
    tc.total_revenue DESC;