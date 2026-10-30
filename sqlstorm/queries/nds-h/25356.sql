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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%steel%'
), SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.s_phone, 
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_comment LIKE '%reliable%'
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, s.s_phone
), OrderInfo AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        c.c_name, 
        c.c_mktsegment,
        COUNT(l.l_orderkey) AS total_lineitems
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate > '1997-01-01' AND o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_mktsegment
)
SELECT 
    rp.p_brand, 
    rp.p_name, 
    sd.s_name AS supplier_name, 
    oi.o_orderkey, 
    oi.o_orderdate, 
    oi.o_totalprice, 
    oi.c_name AS customer_name, 
    oi.total_lineitems   
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    OrderInfo oi ON oi.o_orderkey = ps.ps_partkey
WHERE 
    rp.rn = 1
ORDER BY 
    rp.p_brand, oi.o_totalprice DESC;