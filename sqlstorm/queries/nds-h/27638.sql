WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part AS p
    WHERE 
        p.p_size > 10
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn_supplier
    FROM 
        supplier AS s
    JOIN 
        nation AS n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 1000.00
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    si.s_name AS supplier_name,
    si.nation AS supplier_nation,
    si.s_acctbal AS supplier_acctbal
FROM 
    RankedParts AS rp
JOIN 
    partsupp AS ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierInfo AS si ON ps.ps_suppkey = si.s_suppkey
WHERE 
    rp.rn = 1 
    AND si.rn_supplier <= 5
ORDER BY 
    rp.p_retailprice DESC, 
    si.s_acctbal DESC;
