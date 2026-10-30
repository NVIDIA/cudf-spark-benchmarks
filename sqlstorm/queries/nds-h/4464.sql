WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, s.s_name
),
QualifiedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        AVG(sp.total_supply_value) AS avg_supply_value,
        p.p_retailprice,
        CASE 
            WHEN p.p_retailprice IS NULL THEN 'Price Not Available'
            ELSE 'Price Available'
        END AS price_availability
    FROM 
        part p
    LEFT JOIN 
        SupplierParts sp ON p.p_partkey = sp.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
    HAVING 
        AVG(sp.total_supply_value) > 1000
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.c_name,
    qp.p_name,
    qp.p_retailprice,
    qp.avg_supply_value,
    COUNT(*) OVER (PARTITION BY ro.o_orderkey) AS total_items_sold,
    MAX(qp.avg_supply_value) OVER () AS max_avg_supply_value
FROM 
    RankedOrders ro
JOIN 
    lineitem l ON ro.o_orderkey = l.l_orderkey
JOIN 
    QualifiedParts qp ON l.l_partkey = qp.p_partkey
WHERE 
    ro.rn <= 5
    AND l.l_discount < 0.05
ORDER BY 
    ro.o_orderdate DESC, qp.avg_supply_value DESC;