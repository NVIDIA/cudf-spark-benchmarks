WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_orderdate DESC) AS priority_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_available,
        ss.total_supply_cost,
        DENSE_RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS rank_by_cost
    FROM 
        SupplierStats ss
    WHERE 
        ss.total_available > 0
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.o_orderpriority,
    ts.s_name,
    ts.total_available,
    ts.total_supply_cost
FROM 
    RankedOrders ro
JOIN 
    lineitem li ON ro.o_orderkey = li.l_orderkey
JOIN 
    partsupp ps ON li.l_partkey = ps.ps_partkey
JOIN 
    TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
WHERE 
    ts.rank_by_cost <= 5
ORDER BY 
    ro.o_orderdate DESC, ro.o_totalprice DESC;