WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
), TopOrders AS (
    SELECT 
        r.o_orderkey, 
        r.o_orderdate,
        r.o_totalprice,
        r.c_mktsegment
    FROM 
        RankedOrders r
    WHERE 
        r.rn <= 10
), SupplierParts AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost) AS total_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_brand
), JoinData AS (
    SELECT 
        t.o_orderkey,
        t.o_orderdate,
        t.o_totalprice,
        s.s_suppkey,
        sp.p_name,
        sp.total_available,
        sp.total_cost
    FROM 
        TopOrders t
    JOIN 
        lineitem l ON t.o_orderkey = l.l_orderkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        SupplierParts sp ON l.l_partkey = sp.ps_partkey
)
SELECT 
    j.o_orderkey, 
    j.o_orderdate, 
    j.o_totalprice, 
    j.s_suppkey, 
    j.p_name, 
    j.total_available, 
    j.total_cost, 
    (j.o_totalprice - j.total_cost) AS potential_profit
FROM 
    JoinData j
WHERE 
    j.total_available > 100
ORDER BY 
    j.o_orderdate DESC, j.o_totalprice DESC;
