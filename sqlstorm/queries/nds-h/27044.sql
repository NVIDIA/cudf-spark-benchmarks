
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
        LENGTH(p.p_name) > 10 AND 
        p.p_retailprice > 100.00
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        TRIM(UPPER(s.s_comment)) AS normalized_comment,
        ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS supplier_rank,
        s.s_nationkey
    FROM 
        supplier s
    WHERE 
        s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
),
AggregatedOrders AS (
    SELECT 
        o.o_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_custkey
)

SELECT 
    fp.p_name, 
    fp.p_brand, 
    fs.s_name, 
    fo.total_spent,
    fo.order_count,
    CONCAT('Comment: ', fs.normalized_comment) AS supplier_comment
FROM 
    RankedParts fp
JOIN 
    partsupp ps ON fp.p_partkey = ps.ps_partkey
JOIN 
    FilteredSuppliers fs ON ps.ps_suppkey = fs.s_suppkey
JOIN 
    customer c ON c.c_nationkey = fs.s_nationkey
JOIN 
    AggregatedOrders fo ON c.c_custkey = fo.o_custkey
WHERE 
    fp.rank_per_brand <= 5 AND 
    fs.supplier_rank <= 10
ORDER BY 
    fp.p_brand, fo.total_spent DESC;
