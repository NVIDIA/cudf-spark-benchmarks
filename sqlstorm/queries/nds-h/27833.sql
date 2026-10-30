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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_per_brand
    FROM 
        part p
    WHERE 
        p.p_size > 20 AND 
        p.p_name LIKE '%steel%'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        s.s_acctbal,
        LEFT(s.s_comment, 50) AS short_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 5000
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        CONCAT('Customer Name: ', c.c_name, ', Segment: ', c.c_mktsegment) AS customer_info
    FROM 
        customer c
    WHERE 
        c.c_acctbal > 1000
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    sd.s_name AS supplier_name,
    cd.customer_info,
    rp.p_comment,
    CASE 
        WHEN rp.rank_per_brand <= 5 THEN 'Top Seller'
        ELSE 'Regular'
    END AS sales_category
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    orders o ON ps.ps_partkey = o.o_orderkey
JOIN 
    CustomerDetails cd ON o.o_custkey = cd.c_custkey
WHERE 
    sd.nation_name = 'USA' 
ORDER BY 
    rp.p_retailprice DESC, 
    sd.s_name;
