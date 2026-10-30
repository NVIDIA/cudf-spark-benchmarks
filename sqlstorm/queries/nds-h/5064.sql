WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
),
TopOrders AS (
    SELECT 
        r.o_orderkey, 
        r.o_orderdate,
        r.o_totalprice,
        r.c_name,
        r.c_nationkey
    FROM 
        RankedOrders r
    WHERE 
        r.order_rank <= 5
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_name,
        s.s_name
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > 0
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.o_totalprice,
    t.c_name AS customer_name,
    n.n_name AS nation_name,
    COUNT(sp.ps_partkey) AS total_parts_supplied,
    SUM(sp.ps_supplycost) AS total_supply_cost
FROM 
    TopOrders t
JOIN 
    nation n ON t.c_nationkey = n.n_nationkey
LEFT JOIN 
    SupplierParts sp ON t.o_orderkey = sp.ps_partkey
GROUP BY 
    t.o_orderkey, t.o_orderdate, t.o_totalprice, t.c_name, n.n_name
ORDER BY 
    t.o_orderdate DESC, total_supply_cost DESC
LIMIT 100;