
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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_size = (SELECT MAX(p2.p_size) FROM part p2)
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        SUBSTRING(s.s_comment, 1, 50) AS short_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2
        )
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT('Part: ', p.p_name, ', Supplier: ', s.s_name, ', Available Qty: ', ps.ps_availqty) AS details
    FROM 
        partsupp ps
    JOIN 
        RankedParts p ON ps.ps_partkey = p.p_partkey
    JOIN 
        FilteredSuppliers s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    spd.details,
    COUNT(*) AS total_count,
    SUM(spd.ps_supplycost) AS total_supply_cost
FROM 
    SupplierPartDetails spd
GROUP BY 
    spd.details
HAVING 
    COUNT(*) > 1
ORDER BY 
    total_supply_cost DESC;
