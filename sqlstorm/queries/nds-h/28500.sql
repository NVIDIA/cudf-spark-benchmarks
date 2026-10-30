WITH RankedParts AS (
    SELECT 
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_availqty) as total_availqty,
        AVG(ps.ps_supplycost) as avg_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY SUM(ps.ps_availqty) DESC) as rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_name, p.p_mfgr, p.p_brand, p.p_type
),
TopBrands AS (
    SELECT 
        p_brand,
        COUNT(*) as part_count
    FROM 
        RankedParts
    WHERE 
        rn <= 5
    GROUP BY 
        p_brand
),
SupplierDetails AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_name, s.s_acctbal, n.n_name
)
SELECT 
    tb.p_brand,
    tb.part_count,
    sd.s_name,
    sd.nation_name,
    sd.parts_supplied,
    sd.s_acctbal
FROM 
    TopBrands tb
JOIN 
    SupplierDetails sd ON tb.p_brand = sd.nation_name 
WHERE 
    sd.parts_supplied > 10
ORDER BY 
    tb.part_count DESC, sd.s_acctbal DESC;