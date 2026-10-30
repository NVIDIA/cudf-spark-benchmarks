
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 20
), 
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
), 
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS recent_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
)
SELECT 
    p.p_name,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    AVG(l.l_extendedprice) AS avg_extended_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_discount) AS total_discount,
    MAX(l.l_tax) AS max_tax,
    CASE 
        WHEN MAX(l.l_shipdate) > DATE '1997-01-01' THEN 'Shipped Recently'
        ELSE 'Shipped Long Ago'
    END AS shipping_status
FROM 
    RankedParts p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN 
    RecentOrders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.rn = 1 
    AND (s.s_acctbal IS NOT NULL OR s.s_acctbal < 0)
    AND l.l_quantity > 1
GROUP BY 
    p.p_name, s.s_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    avg_extended_price DESC
LIMIT 50;
