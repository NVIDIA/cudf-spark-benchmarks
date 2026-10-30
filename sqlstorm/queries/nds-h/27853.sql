WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as rn
    FROM 
        part p
    WHERE 
        p.p_brand LIKE '%A%' OR p.p_brand LIKE '%B%'
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 100000 AND s.s_name LIKE '%Corp%'
),
TopNationalRegions AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name,
        RANK() OVER (ORDER BY n.n_name) AS region_rank
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    fs.s_name,
    fs.s_acctbal,
    tn.r_name AS region_name,
    tn.region_rank
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    FilteredSuppliers fs ON ps.ps_suppkey = fs.s_suppkey
JOIN 
    TopNationalRegions tn ON fs.s_nationkey = tn.n_nationkey
WHERE 
    rp.rn <= 5 AND fs.s_acctbal < 500000
ORDER BY 
    rp.p_retailprice DESC, fs.s_acctbal ASC;
