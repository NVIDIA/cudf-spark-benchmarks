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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
    WHERE 
        p.p_size IN (
            SELECT DISTINCT ps.ps_partkey 
            FROM partsupp ps 
            WHERE ps.ps_availqty > 100
        )
), SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        SUBSTRING(s.s_comment, 1, 25) AS short_comment
    FROM 
        supplier s 
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        c.c_phone,
        c.c_mktsegment,
        LENGTH(c.c_comment) AS comment_length
    FROM 
        customer c
    WHERE 
        c.c_acctbal > 5000.00
)

SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    sd.s_name AS supplier_name,
    fc.c_name AS customer_name,
    fc.comment_length
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    orders o ON ps.ps_partkey = o.o_orderkey
JOIN 
    FilteredCustomers fc ON o.o_custkey = fc.c_custkey
WHERE 
    rp.brand_rank <= 3
ORDER BY 
    rp.p_retailprice DESC, fc.comment_length ASC
LIMIT 100;
