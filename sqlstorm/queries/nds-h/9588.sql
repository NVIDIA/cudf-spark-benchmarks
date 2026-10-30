
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        COUNT(ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
),
TopNSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        sp.s_name AS supplier_name,
        rp.p_name AS part_name,
        rp.p_retailprice,
        rp.supplier_count
    FROM 
        RankedParts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        supplier sp ON ps.ps_suppkey = sp.s_suppkey
    JOIN 
        nation n ON sp.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rp.supplier_count > 10
    ORDER BY 
        rp.p_retailprice DESC
    LIMIT 10
)
SELECT 
    region_name, 
    nation_name, 
    supplier_name, 
    part_name,
    p_retailprice
FROM 
    TopNSuppliers
WHERE 
    p_retailprice > (SELECT AVG(rp.p_retailprice) FROM RankedParts rp)
ORDER BY 
    region_name, nation_name;
