WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_discount BETWEEN 0.05 AND 0.10
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
NorthAmericaSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name,
        r.r_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name = 'North America'
)
SELECT 
    na.s_name AS supplier_name,
    rp.o_orderkey AS order_id,
    rp.total_value,
    sp.total_avail_qty,
    sp.avg_supply_cost
FROM 
    RankedOrders rp
JOIN 
    SupplierParts sp ON rp.o_orderkey = sp.ps_partkey
JOIN 
    NorthAmericaSuppliers na ON sp.ps_suppkey = na.s_suppkey
WHERE 
    rp.rn = 1
ORDER BY 
    rp.total_value DESC
LIMIT 10;
