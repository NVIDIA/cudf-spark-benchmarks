WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
    WHERE 
        TRIM(p.p_comment) <> '' AND 
        LENGTH(p.p_name) BETWEEN 10 AND 55
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        ps.ps_availqty,
        ps.ps_supplycost,
        rp.p_name,
        rp.p_retailprice
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        RankedParts rp ON ps.ps_partkey = rp.p_partkey
    WHERE 
        ps.ps_availqty >= 100 AND 
        rp.brand_rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        c.c_phone,
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 1000 AND 
        o.o_orderstatus = 'O'
)
SELECT 
    sp.s_name AS supplier_name,
    sp.p_name AS part_name,
    sp.ps_availqty AS available_quantity,
    co.c_name AS customer_name,
    co.o_totalprice AS order_total,
    co.o_orderdate AS order_date
FROM 
    SupplierParts sp
JOIN 
    CustomerOrders co ON sp.ps_supplycost < co.o_totalprice
WHERE 
    sp.p_retailprice < 50.00
ORDER BY 
    sp.s_name, co.o_orderdate DESC;
