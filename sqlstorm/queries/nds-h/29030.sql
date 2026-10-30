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
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_comment LIKE '%special%')
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s_acctbal) FROM supplier
        )
        AND s.s_comment LIKE '%reliable%'
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment,
        rp.p_name,
        rp.price_rank
    FROM 
        partsupp ps
    JOIN 
        RankedParts rp ON ps.ps_partkey = rp.p_partkey
   WHERE 
        rp.price_rank <= 5
)
SELECT 
    c.c_name AS customer_name,
    psd.p_name AS part_name,
    psd.ps_availqty AS available_quantity,
    psd.ps_supplycost AS supply_cost,
    s.s_name AS supplier_name
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    PartSupplierDetails psd ON l.l_partkey = psd.ps_partkey
JOIN 
    FilteredSuppliers s ON psd.ps_suppkey = s.s_suppkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
ORDER BY 
    c.c_name, psd.p_name, psd.ps_supplycost DESC;