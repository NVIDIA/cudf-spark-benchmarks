
WITH RankedParts AS (
    SELECT 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        p.p_container, 
        p.p_retailprice, 
        p.p_comment,
        DENSE_RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank,
        p.p_partkey
    FROM 
        part p
    WHERE 
        p.p_retailprice > 0
), 

SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name, 
        s.s_address, 
        s.s_phone, 
        s.s_acctbal,
        n.n_name AS supplier_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 1000
),

CustomerOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_orderdate, 
        o.o_totalprice,
        c.c_name AS customer_name,
        c.c_mktsegment
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
)

SELECT 
    rp.p_name, 
    rp.p_brand, 
    rp.p_type, 
    sd.s_name AS supplier_name, 
    sd.s_phone AS supplier_phone, 
    co.customer_name, 
    co.o_orderdate, 
    co.o_totalprice
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    lineitem li ON ps.ps_partkey = li.l_partkey
JOIN 
    CustomerOrders co ON li.l_orderkey = co.o_orderkey
WHERE 
    rp.price_rank <= 5 AND 
    sd.supplier_nation = 'USA' AND 
    co.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
ORDER BY 
    rp.p_brand, co.o_orderdate;
