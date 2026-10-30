WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O' AND o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.c_name
    FROM 
        RankedOrders r
    WHERE 
        r.rank <= 5
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey
),
OrderDetails AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax
    FROM 
        lineitem l
    JOIN 
        TopOrders o ON l.l_orderkey = o.o_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    od.l_partkey,
    od.l_quantity,
    od.l_extendedprice,
    sp.total_available_quantity,
    sp.total_supply_cost
FROM 
    TopOrders o
JOIN 
    OrderDetails od ON o.o_orderkey = od.l_orderkey
JOIN 
    SupplierParts sp ON od.l_partkey = sp.ps_partkey
ORDER BY 
    o.o_orderdate, o.o_orderkey, sp.total_available_quantity DESC;