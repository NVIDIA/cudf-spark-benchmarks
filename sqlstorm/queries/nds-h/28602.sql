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
        p.p_size BETWEEN 1 AND 10
),
SelectedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2 
            WHERE s2.s_comment LIKE '%quality%'
        )
),
ProductDetails AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        ss.s_name AS supplier_name,
        ss.s_address AS supplier_address,
        ss.s_phone AS supplier_phone,
        rp.p_retailprice
    FROM 
        RankedParts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        SelectedSuppliers ss ON ps.ps_suppkey = ss.s_suppkey
    WHERE 
        rp.price_rank <= 5
)
SELECT 
    pd.p_name, 
    pd.supplier_name, 
    pd.p_retailprice,
    CONCAT('Supplier ', pd.supplier_name, ' offers ', pd.p_name, ' at a price of ', CAST(pd.p_retailprice AS VARCHAR(20))) AS offer_details
FROM 
    ProductDetails pd
ORDER BY 
    pd.p_retailprice ASC;
