WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
),
SelectedOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_mktsegment
    FROM 
        RankedOrders ro
    WHERE 
        ro.price_rank <= 10
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_brand
)
SELECT 
    so.o_orderkey,
    so.o_orderdate,
    so.o_totalprice,
    so.c_mktsegment,
    ps.p_name,
    ps.p_brand,
    ps.total_supply_cost
FROM 
    SelectedOrders so
JOIN 
    lineitem l ON so.o_orderkey = l.l_orderkey
JOIN 
    PartSupplierDetails ps ON l.l_partkey = ps.ps_partkey
WHERE 
    ps.total_supply_cost > 1000
ORDER BY 
    so.o_orderdate DESC, so.o_totalprice DESC;