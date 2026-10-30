WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_mfgr,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%steel%'
),
SuppliersInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        s.s_phone,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, s.s_phone, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        si.s_suppkey,
        si.s_name,
        si.nation_name,
        si.s_phone,
        si.s_acctbal,
        si.part_count,
        DENSE_RANK() OVER (ORDER BY si.part_count DESC) AS top_rank
    FROM 
        SuppliersInfo si
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    ts.s_name AS supplier_name,
    ts.nation_name,
    ts.s_phone,
    ts.s_acctbal,
    ts.part_count
FROM 
    RankedParts rp
JOIN 
    lineitem l ON rp.p_partkey = l.l_partkey
JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    ts.top_rank <= 5
ORDER BY 
    rp.p_brand, ts.s_name;
