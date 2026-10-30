WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        p.p_partkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, p.p_partkey
),
SignificantOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_totalprice, 
        o.o_orderstatus, 
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderstatus
),
TopLineItems AS (
    SELECT 
        l.l_orderkey, 
        l.l_partkey, 
        l.l_suppkey, 
        l.l_quantity,
        l.l_extendedprice
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    ORDER BY 
        l.l_extendedprice DESC
    LIMIT 100
)
SELECT 
    ro.o_orderkey,
    ro.o_totalprice,
    ss.s_name AS supplier_name,
    ss.total_cost AS supplier_total_cost,
    ti.l_quantity,
    ti.l_extendedprice
FROM 
    SignificantOrders ro
JOIN 
    RankedSuppliers ss ON ro.o_custkey = ss.s_suppkey
JOIN 
    TopLineItems ti ON ro.o_orderkey = ti.l_orderkey
WHERE 
    ss.supplier_rank = 1
ORDER BY 
    ro.o_orderkey, ss.total_cost DESC;