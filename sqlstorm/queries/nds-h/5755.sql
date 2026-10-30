WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        c.c_name,
        c.c_nationkey,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_order
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
),
TopCustomers AS (
    SELECT 
        ro.rank_order,
        ro.o_orderkey,
        ro.o_orderdate,
        ro.c_name,
        ro.o_totalprice,
        n.n_name AS nation_name
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON ro.c_nationkey = n.n_nationkey
    WHERE 
        ro.rank_order <= 5
),
SupplierParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        s.s_name AS supplier_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.c_name,
    t.nation_name,
    sp.p_partkey,
    sp.p_name,
    sp.ps_availqty,
    sp.ps_supplycost,
    t.o_totalprice,
    (sp.ps_supplycost * sp.ps_availqty) AS total_supply_cost
FROM 
    TopCustomers t
JOIN 
    SupplierParts sp ON t.o_orderkey % 5 = sp.p_partkey % 5
WHERE 
    t.o_totalprice > 1000
ORDER BY 
    t.o_orderdate DESC, t.o_totalprice DESC;