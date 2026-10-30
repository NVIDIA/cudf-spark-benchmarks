
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
),
TopSuppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_mktsegment
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
)
SELECT 
    rp.p_name,
    rp.p_retailprice,
    ts.s_name,
    ts.s_acctbal,
    co.o_orderkey,
    co.o_orderdate,
    co.o_totalprice,
    co.c_name,
    co.c_mktsegment
FROM 
    RankedParts rp
JOIN 
    TopSuppliers ts ON rp.p_partkey = ts.ps_partkey 
JOIN 
    lineitem li ON li.l_partkey = rp.p_partkey
JOIN 
    CustomerOrders co ON li.l_orderkey = co.o_orderkey
WHERE 
    ts.supplier_rank <= 5
    AND rp.price_rank <= 10
ORDER BY 
    rp.p_retailprice DESC, 
    ts.s_acctbal DESC, 
    co.o_orderdate DESC;
