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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as rank
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%widget%'
),
SupplierCounts AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_phone
    HAVING 
        SUM(ps.ps_supplycost) > 10000
),
FinalResult AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_mfgr,
        rp.p_brand,
        rp.p_type,
        rp.p_size,
        rp.p_container,
        rp.p_retailprice,
        rp.p_comment,
        sc.supplier_count,
        hvs.total_supply_cost
    FROM 
        RankedParts rp
    JOIN 
        SupplierCounts sc ON rp.p_partkey = sc.ps_partkey
    JOIN 
        HighValueSuppliers hvs ON hvs.total_supply_cost > 20000
    WHERE 
        rp.rank <= 5
)
SELECT 
    f.p_partkey,
    f.p_name,
    f.p_mfgr,
    f.p_brand,
    f.p_type,
    f.p_size,
    f.p_container,
    f.p_retailprice,
    f.p_comment,
    f.supplier_count,
    f.total_supply_cost
FROM 
    FinalResult f
ORDER BY 
    f.p_brand, f.p_retailprice DESC;
