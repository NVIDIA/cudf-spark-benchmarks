WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
        AND o.o_orderdate < DATE '1997-12-31'
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        RankedOrders ro
    JOIN 
        lineitem l ON ro.o_orderkey = l.l_orderkey
    WHERE 
        ro.order_rank <= 10
    GROUP BY 
        ro.o_orderkey, ro.o_orderdate, ro.o_totalprice
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    ORDER BY 
        total_supply_cost DESC
    LIMIT 5
)
SELECT 
    h.o_orderkey,
    h.o_orderdate,
    h.total_value,
    s.s_name,
    s.total_supply_cost
FROM 
    HighValueOrders h
JOIN 
    lineitem l ON h.o_orderkey = l.l_orderkey
JOIN 
    TopSuppliers s ON l.l_suppkey = s.s_suppkey
ORDER BY 
    h.total_value DESC, s.total_supply_cost DESC;