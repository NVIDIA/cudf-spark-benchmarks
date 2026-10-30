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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
TopPartSuppliers AS (
    SELECT 
        r.p_partkey,
        r.rank,
        f.s_suppkey,
        f.s_name,
        f.nation_name
    FROM 
        RankedParts r
    JOIN 
        partsupp ps ON r.p_partkey = ps.ps_partkey
    JOIN 
        FilteredSuppliers f ON ps.ps_suppkey = f.s_suppkey
    WHERE 
        r.rank <= 3
)
SELECT 
    t.p_partkey,
    t.rank,
    t.s_suppkey,
    t.s_name,
    t.nation_name,
    COUNT(*) AS total_supply_options
FROM 
    TopPartSuppliers t
GROUP BY 
    t.p_partkey, t.rank, t.s_suppkey, t.s_name, t.nation_name
ORDER BY 
    t.p_partkey, t.rank;
