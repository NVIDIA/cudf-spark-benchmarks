WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        c.c_mktsegment,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) as price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate <= DATE '1997-12-31'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
ExtendedLineItems AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        SUM(li.l_quantity) AS total_quantity,
        COUNT(DISTINCT li.l_linestatus) AS distinct_line_status
    FROM 
        lineitem li
    GROUP BY 
        li.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderstatus,
    r.o_totalprice,
    r.o_orderdate,
    r.o_orderpriority,
    r.c_mktsegment,
    sp.total_avail_qty,
    sp.total_supply_cost,
    el.total_revenue,
    el.total_quantity,
    el.distinct_line_status
FROM 
    RankedOrders r
JOIN 
    SupplierParts sp ON r.o_orderkey = sp.ps_partkey
JOIN 
    ExtendedLineItems el ON r.o_orderkey = el.l_orderkey
WHERE 
    r.price_rank <= 5
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;