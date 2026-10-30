WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS segment_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
),
high_value_orders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_mktsegment
    FROM 
        ranked_orders ro
    WHERE 
        ro.segment_rank <= 10
),
supplier_parts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
aggregate_data AS (
    SELECT 
        hp.o_orderkey,
        SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS total_line_amount,
        AVG(sp.total_supply_value) AS avg_supplier_value
    FROM 
        high_value_orders hp
    JOIN 
        lineitem lp ON hp.o_orderkey = lp.l_orderkey
    JOIN 
        supplier_parts sp ON lp.l_partkey = sp.ps_partkey
    GROUP BY 
        hp.o_orderkey
)

SELECT 
    h.o_orderkey,
    h.o_orderdate,
    h.c_mktsegment,
    a.total_line_amount,
    a.avg_supplier_value
FROM 
    high_value_orders h
JOIN 
    aggregate_data a ON h.o_orderkey = a.o_orderkey
ORDER BY 
    a.total_line_amount DESC, 
    h.o_orderdate ASC;