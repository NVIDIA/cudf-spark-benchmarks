WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        c.c_mktsegment
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.o_orderkey = c.c_custkey
    WHERE 
        ro.order_rank <= 5
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        l.l_quantity,
        l.l_extendedprice
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderkey IN (SELECT o_orderkey FROM TopOrders)
)
SELECT 
    sd.s_name,
    SUM(sd.l_extendedprice) AS total_revenue,
    SUM(sd.ps_availqty) AS total_available_quantity,
    AVG(sd.ps_supplycost) AS average_supply_cost
FROM 
    SupplierDetails sd
GROUP BY 
    sd.s_name
ORDER BY 
    total_revenue DESC
LIMIT 10;