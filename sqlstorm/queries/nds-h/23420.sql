
WITH RankedPrices AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
), 
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
), 
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        MIN(ps.ps_supplycost) AS min_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), 
LateShipments AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        COUNT(*) AS late_shipment_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate > l.l_commitdate
    GROUP BY 
        l.l_orderkey, l.l_partkey
)
SELECT 
    c.c_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(rp.p_retailprice) AS max_price,
    AVG(sp.total_available) AS avg_available_parts,
    COALESCE(SUM(ls.late_shipment_count), 0) AS total_late_shipments
FROM 
    HighValueCustomers c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    RankedPrices rp ON l.l_partkey = rp.p_partkey AND rp.price_rank = 1
LEFT JOIN 
    SupplierParts sp ON l.l_partkey = sp.ps_partkey
LEFT JOIN 
    LateShipments ls ON l.l_orderkey = ls.l_orderkey AND l.l_partkey = ls.l_partkey
WHERE 
    l.l_returnflag <> 'R' AND 
    l.l_shipmode IN ('AIR', 'TRUCK') AND 
    l.l_extendedprice > 0
GROUP BY 
    c.c_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(total_spent) FROM HighValueCustomers)
ORDER BY 
    total_revenue DESC
LIMIT 10;
