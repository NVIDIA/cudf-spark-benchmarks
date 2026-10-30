WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice, 
        o.o_orderdate, 
        o.o_orderpriority, 
        c.c_mktsegment, 
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND 
        o.o_orderdate < DATE '1997-12-31'
),
TopOrders AS (
    SELECT 
        r.o_orderkey, 
        r.o_orderstatus, 
        r.o_totalprice, 
        r.o_orderdate, 
        r.o_orderpriority, 
        r.c_mktsegment
    FROM 
        RankedOrders r
    WHERE 
        r.rn <= 10
),
SupplierDetails AS (
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
)
SELECT 
    co.o_orderkey, 
    co.o_totalprice, 
    sd.s_name, 
    sd.total_supply_cost
FROM 
    TopOrders co
JOIN 
    lineitem li ON co.o_orderkey = li.l_orderkey
JOIN 
    SupplierDetails sd ON li.l_suppkey = sd.s_suppkey
WHERE 
    co.o_orderstatus = 'F'
ORDER BY 
    co.o_totalprice DESC, sd.total_supply_cost ASC;