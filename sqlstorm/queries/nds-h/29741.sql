
WITH RankedSupps AS (
    SELECT 
        ps_partkey, 
        ps_suppkey, 
        s_name AS supp_name, 
        ps_availqty, 
        ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost DESC) AS rn
    FROM partsupp
    JOIN supplier ON partsupp.ps_suppkey = supplier.s_suppkey
), FilteredParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        SUM(l.l_quantity) AS total_quantity
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE p.p_brand LIKE 'Brand%TTL%%' 
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_type
    HAVING SUM(l.l_quantity) > 100
), SupplierDetails AS (
    SELECT 
        fs.ps_partkey, 
        fs.supp_name, 
        fs.ps_availqty, 
        fs.ps_supplycost
    FROM RankedSupps fs
    WHERE fs.rn = 1
)
SELECT 
    fp.p_name, 
    fp.p_brand, 
    fp.p_type,
    sd.supp_name,
    sd.ps_availqty,
    sd.ps_supplycost,
    fp.total_quantity
FROM FilteredParts fp
JOIN SupplierDetails sd ON fp.p_partkey = sd.ps_partkey
ORDER BY sd.ps_supplycost, fp.total_quantity DESC;
