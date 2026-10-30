WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        c.c_nationkey,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        p.p_name,
        SUM(ps.ps_availqty) as total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) as total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey, p.p_name
)
SELECT 
    ro.o_orderkey,
    ro.o_orderstatus,
    ro.o_totalprice,
    ro.o_orderdate,
    ro.o_orderpriority,
    sp.p_name,
    sp.total_avail_qty,
    sp.total_supply_cost
FROM 
    RankedOrders ro
JOIN 
    lineitem l ON ro.o_orderkey = l.l_orderkey
JOIN 
    SupplierPartDetails sp ON l.l_partkey = sp.ps_partkey
WHERE 
    ro.order_rank <= 5 AND sp.total_avail_qty > 100
ORDER BY 
    ro.o_orderdate DESC, ro.o_totalprice DESC;