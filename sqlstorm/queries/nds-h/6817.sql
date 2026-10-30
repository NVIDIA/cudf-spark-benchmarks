WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o 
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_name IN ('FRANCE', 'GERMANY', 'USA')
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        sp.ps_suppkey,
        SUM(sp.total_supply_cost) AS total_cost
    FROM 
        SupplierParts sp
    GROUP BY 
        sp.ps_suppkey
    ORDER BY 
        total_cost DESC
    LIMIT 5
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.o_orderpriority,
    ts.ps_suppkey,
    sp.total_avail_qty,
    sp.total_supply_cost
FROM 
    RankedOrders ro
JOIN 
    lineitem li ON ro.o_orderkey = li.l_orderkey
JOIN 
    SupplierParts sp ON li.l_partkey = sp.ps_partkey
JOIN 
    TopSuppliers ts ON sp.ps_suppkey = ts.ps_suppkey
WHERE 
    ro.order_rank <= 10
ORDER BY 
    ro.o_totalprice DESC, ts.total_cost DESC;
