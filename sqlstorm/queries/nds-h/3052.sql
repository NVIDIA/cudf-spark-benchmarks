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
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderstatus = 'O'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 1000
    GROUP BY 
        s.s_suppkey, s.s_name
),
AggregatedLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(*) AS total_lines,
        AVG(l.l_tax) AS avg_tax_rate
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate > cast('1998-10-01' as date) - INTERVAL '90 days'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    s.s_name,
    s.total_avail_qty,
    s.unique_parts,
    a.total_sales,
    a.total_lines,
    a.avg_tax_rate
FROM 
    RankedOrders o
LEFT JOIN 
    SupplierInfo s ON s.unique_parts > 5
LEFT JOIN 
    AggregatedLineItems a ON o.o_orderkey = a.l_orderkey
WHERE 
    o.rn <= 10
ORDER BY 
    o.o_totalprice DESC, 
    s.total_avail_qty ASC;