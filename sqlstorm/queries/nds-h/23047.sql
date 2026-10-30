WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        RankedParts p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
HighValueSuppliers AS (
    SELECT 
        ss.s_suppkey
    FROM 
        SupplierStats ss
    WHERE 
        ss.total_supply_value > (SELECT AVG(total_supply_value) FROM SupplierStats)
),
DistinctOrderCustomers AS (
    SELECT DISTINCT 
        co.c_custkey
    FROM 
        CustomerOrders co
    JOIN 
        HighValueSuppliers hvs ON co.c_custkey IN (SELECT DISTINCT o.o_custkey FROM orders o)
)
SELECT 
    r.r_name,
    COUNT(DISTINCT p.p_partkey) AS total_parts,
    SUM(CASE WHEN ps.ps_supplycost IS NULL THEN 0 ELSE ps.ps_supplycost END) AS total_supply_cost,
    SUM(CASE WHEN p.p_retailprice > 100 THEN p.p_retailprice ELSE 0 END) AS total_high_value_parts,
    COUNT(DISTINCT doc.c_custkey) AS distinct_order_customers
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    RankedParts p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = s.s_suppkey
LEFT JOIN 
    DistinctOrderCustomers doc ON doc.c_custkey = co.c_custkey
WHERE 
    p.p_mfgr IS NOT NULL AND 
    (ps.ps_availqty > 0 OR ps.ps_supplycost NOT BETWEEN 50 AND 100) AND 
    (r.r_comment IS NULL OR r.r_comment LIKE '%important%')
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT p.p_partkey) > 5
ORDER BY 
    total_parts DESC, 
    total_supply_cost ASC;
