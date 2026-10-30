
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, s.s_name, s.s_acctbal
),
TotalLineItem AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_amount,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_orderstatus,
    COALESCE(tla.total_line_amount, 0) AS total_line_amount,
    COALESCE(tla.line_count, 0) AS line_count,
    s.s_name,
    s.total_supply_cost
FROM 
    RankedOrders r
LEFT JOIN 
    TotalLineItem tla ON r.o_orderkey = tla.l_orderkey
LEFT JOIN 
    SupplierCost s ON s.ps_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0)
WHERE 
    r.rn <= 5
    AND (s.s_acctbal IS NULL OR s.s_acctbal > 10000.00)
ORDER BY 
    r.o_orderkey;
