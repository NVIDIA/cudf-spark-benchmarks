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
        p.p_name LIKE '%soft%'
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s1.s_acctbal) 
            FROM supplier s1
        )
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        o.o_comment
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O' 
        AND o.o_totalprice > 1000
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    hvs.s_suppkey,
    hvs.s_name,
    fo.o_orderkey,
    fo.o_totalprice,
    fo.o_orderdate
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    HighValueSuppliers hvs ON ps.ps_suppkey = hvs.s_suppkey
JOIN 
    lineitem li ON ps.ps_partkey = li.l_partkey
JOIN 
    FilteredOrders fo ON li.l_orderkey = fo.o_orderkey
WHERE 
    rp.rank <= 5
ORDER BY 
    rp.p_retailprice DESC, hvs.s_acctbal DESC;
