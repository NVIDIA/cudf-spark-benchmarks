WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY ps.ps_availqty DESC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
),
TopParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.ps_availqty
    FROM 
        RankedParts rp
    WHERE 
        rp.rn <= 5
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_phone,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS parts_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_phone, s.s_acctbal
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    sd.s_name AS supplier_name,
    sd.s_phone AS supplier_phone,
    sd.parts_count,
    rp.ps_availqty
FROM 
    TopParts rp
JOIN 
    SupplierDetails sd ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s))
ORDER BY 
    rp.ps_availqty DESC, sd.parts_count DESC;
