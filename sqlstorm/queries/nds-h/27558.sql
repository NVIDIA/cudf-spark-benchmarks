
WITH PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name,
        p.p_brand,
        p.p_mfgr,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        CONCAT(p.p_mfgr, ' - ', p.p_name) AS full_description
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
), SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.s_nationkey, 
        s.s_phone, 
        s.s_acctbal, 
        s.s_comment
    FROM supplier s
    WHERE s.s_acctbal > 5000
), ProductSupplier AS (
    SELECT 
        pd.full_description, 
        sd.s_name,
        sd.s_address,
        (pd.p_retailprice * ps.ps_availqty) AS inventory_value
    FROM PartDetails pd
    JOIN partsupp ps ON pd.p_partkey = ps.ps_partkey
    JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
)
SELECT 
    CONCAT('Supplier ', ps.s_name, ' supplies ', ps.full_description, ' with an inventory value of $', CAST(ps.inventory_value AS VARCHAR(20))) AS inventory_report
FROM ProductSupplier ps
ORDER BY ps.inventory_value DESC;
