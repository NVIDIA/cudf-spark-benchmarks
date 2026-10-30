
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
TopSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 1000
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
OrderLineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity,
        SUM(CASE WHEN l.l_returnflag = 'Y' THEN 1 ELSE 0 END) AS return_count
    FROM 
        lineitem l
    JOIN 
        RankedOrders ro ON l.l_orderkey = ro.o_orderkey
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    c.c_name,
    ts.ps_suppkey,
    ol.total_revenue,
    ol.avg_quantity,
    ol.return_count
FROM 
    RankedOrders ro
JOIN 
    customer c ON ro.c_nationkey = c.c_nationkey
JOIN 
    TopSuppliers ts ON ts.ps_suppkey = ro.o_orderkey % 10  
JOIN 
    OrderLineItemStats ol ON ro.o_orderkey = ol.l_orderkey
WHERE 
    ro.order_rank <= 10
ORDER BY 
    ro.o_totalprice DESC, ol.total_revenue DESC;
