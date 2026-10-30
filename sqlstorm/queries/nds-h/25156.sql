WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
FilteredParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_retailprice,
        psd.total_supplier_balance
    FROM 
        RankedParts rp
    JOIN 
        PartSupplierDetails psd ON rp.p_partkey = psd.ps_partkey
    WHERE 
        rp.rank <= 10 AND 
        rp.p_brand LIKE 'Brand%'
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.p_brand,
    fp.p_retailprice,
    fp.total_supplier_balance,
    CONCAT(fp.p_name, ' - ', fp.p_brand) AS product_description,
    CASE 
        WHEN fp.total_supplier_balance > 100000 THEN 'High'
        WHEN fp.total_supplier_balance BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'Low'
    END AS supplier_balance_category
FROM 
    FilteredParts fp
ORDER BY 
    fp.p_retailprice DESC, 
    fp.total_supplier_balance ASC;
