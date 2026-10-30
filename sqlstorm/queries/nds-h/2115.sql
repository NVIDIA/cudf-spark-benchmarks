WITH RankedOrders AS (
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
        o.o_orderdate >= DATE '1996-01-01'
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_nationkey
),
OrderDetails AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_discount,
        l.l_tax,
        l.l_extendedprice,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS line_number
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1996-01-01'
),
CombinedData AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_mktsegment,
        od.l_partkey,
        od.l_quantity,
        od.l_discount,
        od.l_tax,
        od.l_extendedprice,
        COALESCE(ss.total_supply_value, 0) AS total_supply_value
    FROM 
        RankedOrders ro
    LEFT JOIN 
        OrderDetails od ON ro.o_orderkey = od.l_orderkey
    LEFT JOIN 
        SupplierStats ss ON od.l_partkey = ss.ps_partkey
    WHERE 
        ro.segment_rank <= 10
)
SELECT 
    r.o_orderdate,
    r.c_mktsegment,
    SUM(r.total_supply_value) AS total_supply_per_segment,
    AVG(r.l_extendedprice) AS avg_extended_price_per_order,
    COUNT(DISTINCT r.l_partkey) AS unique_parts_count
FROM 
    CombinedData r
GROUP BY 
    r.o_orderdate, r.c_mktsegment
HAVING 
    SUM(r.total_supply_value) > 10000
ORDER BY 
    r.o_orderdate DESC, r.c_mktsegment;