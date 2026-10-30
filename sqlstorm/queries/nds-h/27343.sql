WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_price,
        LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 30
),
DistinctSuppliers AS (
    SELECT DISTINCT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        LENGTH(s.s_comment) AS supplier_comment_length
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_name LIKE '%land%'
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.rank_price,
    ds.s_name,
    ds.nation_name,
    ds.supplier_comment_length,
    rp.comment_length
FROM 
    RankedParts rp
JOIN 
    DistinctSuppliers ds ON rp.p_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_suppkey IN (
            SELECT l.l_suppkey 
            FROM lineitem l 
            WHERE l.l_returnflag = 'R' AND l.l_shipdate > '1997-01-01'
        )
    )
WHERE 
    rp.rank_price <= 5
ORDER BY 
    rp.p_brand, rp.p_retailprice DESC, ds.s_name;