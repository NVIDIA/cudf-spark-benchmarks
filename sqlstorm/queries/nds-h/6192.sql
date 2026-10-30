
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice, 
        o.o_orderdate, 
        o.o_orderpriority, 
        c.c_mktsegment, 
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) as rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
), HighestValueOrders AS (
    SELECT 
        r.c_mktsegment, 
        COUNT(*) as order_count, 
        SUM(o.o_totalprice) as total_revenue
    FROM 
        RankedOrders r
    JOIN 
        orders o ON r.o_orderkey = o.o_orderkey
    WHERE 
        r.rn <= 10
    GROUP BY 
        r.c_mktsegment
), SupplierParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        ps.ps_supplycost, 
        s.s_name, 
        s.s_acctbal
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > 0
), AllData AS (
    SELECT 
        h.c_mktsegment, 
        h.order_count, 
        h.total_revenue, 
        sp.p_name, 
        sp.ps_supplycost, 
        sp.s_name
    FROM 
        HighestValueOrders h
    LEFT JOIN 
        SupplierParts sp ON h.c_mktsegment = sp.p_name
)
SELECT 
    m.c_mktsegment, 
    m.order_count, 
    m.total_revenue, 
    COUNT(DISTINCT sp.s_name) as supplier_count, 
    AVG(sp.ps_supplycost) as avg_supply_cost
FROM 
    AllData m
LEFT JOIN 
    SupplierParts sp ON m.p_name = sp.p_name
GROUP BY 
    m.c_mktsegment, 
    m.order_count, 
    m.total_revenue
ORDER BY 
    m.total_revenue DESC;
