WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND 
        o.o_orderdate < DATE '1997-01-01'
), TotalSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
), SupplierPerformance AS (
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
), EffectiveProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > 100 AND 
        p.p_size BETWEEN 10 AND 20
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.o_orderpriority,
    COALESCE(ts.total_revenue, 0) AS total_revenue,
    ep.p_name,
    ep.supplier_count,
    ep.avg_supply_cost,
    sp.total_supply_cost
FROM 
    RankedOrders r
LEFT JOIN 
    TotalSales ts ON r.o_orderkey = ts.l_orderkey
LEFT JOIN 
    EffectiveProducts ep ON ep.avg_supply_cost < 50
JOIN 
    SupplierPerformance sp ON sp.total_supply_cost < 5000
WHERE 
    r.rn <= 5 
ORDER BY 
    r.o_orderpriority, r.o_totalprice DESC;