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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_price
    FROM part p
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.s_nationkey, 
        s.s_phone, 
        s.s_acctbal, 
        s.s_comment
    FROM supplier s
    WHERE s.s_acctbal > 1000
),
CombinedData AS (
    SELECT 
        p.p_name, 
        s.s_name, 
        s.s_address, 
        s.s_acctbal, 
        r.r_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM RankedParts p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN FilteredSuppliers s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE p.rank_price <= 5
    GROUP BY p.p_name, s.s_name, s.s_address, s.s_acctbal, r.r_name
)
SELECT 
    CONCAT('Supplier: ', cd.s_name, ', Address: ', cd.s_address, ', Region: ', cd.r_name, ', Parts: ', cd.part_count) AS supplier_info
FROM CombinedData cd
ORDER BY cd.part_count DESC;
