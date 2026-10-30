WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1993-01-01' AND o.o_orderdate < DATE '1994-01-01' 
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), TopSellingParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_partkey
    ORDER BY 
        total_quantity DESC
    LIMIT 10
), SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS supplier_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), HighPriorityOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_orderpriority, 
        custom.c_name,
        custom.c_mktsegment
    FROM 
        orders o
    JOIN 
        customer custom ON o.o_custkey = custom.c_custkey
    WHERE 
        o.o_orderpriority IN ('1-URGENT', '2-HIGH')
)

SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.revenue,
    tps.ps_partkey,
    tps.total_quantity,
    si.s_name,
    si.supplier_nation,
    hpo.o_orderstatus,
    hpo.o_orderpriority,
    hpo.c_name,
    hpo.c_mktsegment
FROM 
    RankedOrders ro
JOIN 
    TopSellingParts tps ON ro.o_orderkey = tps.ps_partkey
JOIN 
    SupplierInfo si ON si.s_suppkey = tps.ps_partkey
JOIN 
    HighPriorityOrders hpo ON ro.o_orderkey = hpo.o_orderkey
ORDER BY 
    ro.revenue DESC, 
    tps.total_quantity DESC
LIMIT 50;
