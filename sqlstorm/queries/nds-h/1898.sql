WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
OrderDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_orderstatus,
    COALESCE(dp.total_line_price, 0) AS order_total_price,
    sp.total_supply_cost,
    sp.num_suppliers
FROM 
    RankedOrders r
LEFT JOIN 
    OrderDetails dp ON r.o_orderkey = dp.l_orderkey
JOIN 
    (SELECT 
         p.p_partkey, 
         p.p_name, 
         p.p_brand, 
         p.p_retailprice,
         sp.total_supply_cost,
         sp.num_suppliers
     FROM 
         part p
     JOIN 
         SupplierParts sp ON p.p_partkey = sp.ps_partkey
     WHERE 
         p.p_retailprice > 20
     ) sp ON dp.line_count > 0
WHERE 
    r.rn <= 10
ORDER BY 
    r.o_orderdate DESC, 
    r.o_orderkey;