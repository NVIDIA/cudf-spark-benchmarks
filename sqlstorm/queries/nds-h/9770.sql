
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-10-01'
),
HighValueOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.c_name,
        r.c_acctbal
    FROM 
        RankedOrders r
    WHERE 
        r.price_rank <= 10
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
SupplierOrders AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        SUM(l.l_extendedprice - (l.l_extendedprice * l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        HighValueOrders hvo ON l.l_orderkey = hvo.o_orderkey
    GROUP BY 
        l.l_orderkey, l.l_partkey, l.l_suppkey
)
SELECT 
    hvo.o_orderkey,
    hvo.o_orderdate,
    hvo.c_name,
    hvo.o_totalprice,
    s.total_availqty,
    s.avg_supplycost,
    so.total_revenue
FROM 
    HighValueOrders hvo
LEFT JOIN 
    SupplierOrders so ON hvo.o_orderkey = so.l_orderkey
LEFT JOIN 
    SupplierStats s ON so.l_partkey = s.ps_partkey AND so.l_suppkey = s.ps_suppkey
ORDER BY 
    hvo.o_orderdate DESC, 
    hvo.o_totalprice DESC;
