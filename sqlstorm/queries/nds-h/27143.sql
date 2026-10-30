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
    WHERE 
        p.p_size BETWEEN 5 AND 15
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS supplier_nation,
        s.s_phone,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 10000
),
JoinResults AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        fs.s_suppkey,
        fs.s_name,
        fs.s_address,
        fs.s_phone,
        fs.s_acctbal,
        rp.rank
    FROM 
        RankedParts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        FilteredSuppliers fs ON ps.ps_suppkey = fs.s_suppkey
)
SELECT 
    j.p_partkey,
    j.p_name,
    j.p_brand,
    j.s_suppkey,
    j.s_name,
    j.s_address,
    j.s_phone,
    j.s_acctbal,
    j.rank
FROM 
    JoinResults j
WHERE 
    j.rank <= 5
ORDER BY 
    j.p_brand, j.s_acctbal DESC;
