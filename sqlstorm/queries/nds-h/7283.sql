WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
), HighValueSuppliers AS (
    SELECT 
        ps.ps_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 1000000
), HighValueLineItems AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS high_value
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
)

SELECT 
    r.o_orderkey, 
    r.o_orderdate, 
    r.o_totalprice, 
    n.n_name AS supplier_nation,
    s.s_name AS supplier_name,
    hvl.high_value AS order_value
FROM 
    RankedOrders r
JOIN 
    HighValueLineItems hvl ON r.o_orderkey = hvl.l_orderkey
JOIN 
    supplier s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps)
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    HighValueSuppliers hvs ON s.s_suppkey = hvs.ps_suppkey
WHERE 
    r.order_rank <= 5
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;