
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
        ROW_NUMBER() OVER(PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
),
ModifiedNames AS (
    SELECT 
        rp.p_partkey,
        CONCAT('Part-', rp.p_name) AS modified_name,
        rp.p_mfgr,
        rp.p_brand,
        rp.p_type,
        rp.p_size,
        rp.p_container,
        rp.p_retailprice,
        rp.p_comment
    FROM 
        RankedParts rp 
    WHERE 
        rp.rn <= 10
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_partkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty > 100
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        o.o_clerk,
        o.o_shippriority,
        o.o_comment
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
FinalOutput AS (
    SELECT 
        mn.modified_name,
        sd.s_name AS supplier_name,
        co.c_name AS customer_name,
        co.o_totalprice,
        sd.s_suppkey
    FROM 
        ModifiedNames mn
    JOIN 
        SupplierDetails sd ON mn.p_partkey = sd.ps_partkey
    JOIN 
        CustomerOrders co ON sd.s_suppkey = co.o_orderkey
)
SELECT 
    modified_name,
    supplier_name,
    customer_name,
    SUM(o_totalprice) AS total_order_value
FROM 
    FinalOutput
GROUP BY 
    modified_name, supplier_name, customer_name
ORDER BY 
    total_order_value DESC;
