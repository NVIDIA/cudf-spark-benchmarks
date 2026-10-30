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
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS Rank
    FROM part p
),
FilteredRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        LENGTH(r.r_comment) AS CommentLength,
        TRIM(r.r_comment) AS TrimmedComment
    FROM region r
    WHERE r.r_name LIKE 'A%' AND LENGTH(r.r_comment) > 100
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUBSTRING(s.s_address FROM 1 FOR 20) AS ShortAddress,
        CONCAT(s.s_name, ' - ', s.s_address) AS SupplierAddress,
        s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
),
CustomerPriority AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        COUNT(o.o_orderkey) AS TotalOrders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_mktsegment
    HAVING COUNT(o.o_orderkey) > 5
)
SELECT 
    rp.p_name,
    rp.p_mfgr,
    rp.p_brand,
    fr.r_name,
    sd.ShortAddress,
    cp.c_name,
    cp.TotalOrders,
    CAST(SUM(l.l_extendedprice * (1 - l.l_discount)) AS DECIMAL(12, 2)) AS TotalRevenue
FROM RankedParts rp
JOIN lineitem l ON rp.p_partkey = l.l_partkey
JOIN FilteredRegions fr ON fr.r_regionkey = (SELECT MIN(r_regionkey) FROM region)
JOIN SupplierDetails sd ON sd.s_suppkey = l.l_suppkey
JOIN CustomerPriority cp ON cp.c_custkey = l.l_orderkey
WHERE rp.Rank <= 10
GROUP BY 
    rp.p_name, 
    rp.p_mfgr, 
    rp.p_brand, 
    fr.r_name, 
    sd.ShortAddress, 
    cp.c_name, 
    cp.TotalOrders
ORDER BY TotalRevenue DESC;
