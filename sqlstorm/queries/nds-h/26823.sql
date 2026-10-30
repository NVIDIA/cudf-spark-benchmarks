WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_mfgr,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY LENGTH(p.p_name) DESC) AS rank_by_size
    FROM 
        part p
    WHERE 
        p.p_size > 10
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_comment,
        SUBSTRING(s.s_address FROM 1 FOR 20) AS short_address
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 50000
),
OrdersSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    fs.s_name AS supplier_name,
    fs.short_address,
    os.lineitem_count,
    os.total_revenue
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    FilteredSuppliers fs ON ps.ps_suppkey = fs.s_suppkey
JOIN 
    OrdersSummary os ON os.o_custkey = fs.s_nationkey 
WHERE 
    rp.rank_by_size = 1
ORDER BY 
    os.total_revenue DESC, rp.p_name ASC;