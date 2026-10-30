WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
),
HighValueOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        n.n_name AS nation_name
    FROM 
        RankedOrders r
    JOIN 
        nation n ON r.c_nationkey = n.n_nationkey
    WHERE 
        r.rank <= 10
),
SupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_availability,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey,
        ps.ps_suppkey
)
SELECT 
    h.o_orderkey,
    h.o_orderdate,
    h.o_totalprice,
    h.nation_name,
    s.total_availability,
    s.avg_supply_cost
FROM 
    HighValueOrders h
JOIN 
    lineitem l ON h.o_orderkey = l.l_orderkey
JOIN 
    SupplierInfo s ON l.l_partkey = s.ps_partkey AND l.l_suppkey = s.ps_suppkey
WHERE 
    h.o_totalprice > 1000
ORDER BY 
    h.o_orderdate DESC, 
    h.o_totalprice DESC
LIMIT 50;