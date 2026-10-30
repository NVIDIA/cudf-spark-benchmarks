WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        c.c_name,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
TopSupps AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size > 10
    GROUP BY 
        ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ts.total_supply_value,
        RANK() OVER (ORDER BY ts.total_supply_value DESC) AS rank
    FROM 
        supplier s
    JOIN 
        TopSupps ts ON s.s_suppkey = ts.ps_suppkey
)
SELECT 
    ro.o_orderkey,
    ro.c_name,
    ro.o_orderdate,
    ro.o_orderstatus,
    ro.o_totalprice,
    ts.s_name AS top_supplier,
    ts.total_supply_value
FROM 
    RankedOrders ro
JOIN 
    lineitem li ON ro.o_orderkey = li.l_orderkey
JOIN 
    TopSuppliers ts ON li.l_suppkey = ts.s_suppkey
WHERE 
    ro.price_rank <= 5 AND ts.rank <= 10
ORDER BY 
    ro.o_orderdate DESC, ro.o_orderkey;