WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size <= 20
        AND p.p_retailprice > 50.00
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 100000.00
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_mktsegment = 'BUILDING'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    rp.p_name,
    rp.p_brand,
    s.s_name AS supplier_name,
    cs.c_name AS customer_name,
    cs.total_spent,
    s.total_supply_cost,
    rp.p_retailprice
FROM 
    RankedParts rp
JOIN 
    SupplierStats s ON rp.p_partkey = s.part_count
JOIN 
    CustomerSummary cs ON cs.total_orders > 5
WHERE 
    rp.rn <= 3
ORDER BY 
    cs.total_spent DESC, rp.p_retailprice DESC;
