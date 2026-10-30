WITH RankedParts AS (
    SELECT 
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%steel%' AND 
        p.p_size BETWEEN 10 AND 20
),
SupplierInfo AS (
    SELECT 
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_name IN ('USA', 'Canada')
),
OrderInfo AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        d.l_quantity,
        d.l_discount,
        d.l_extendedprice
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem d ON o.o_orderkey = d.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' AND 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
FinalBenchmark AS (
    SELECT 
        rp.p_name,
        rp.p_brand,
        rp.p_retailprice,
        si.s_name,
        si.nation_name,
        oi.o_totalprice,
        oi.o_orderdate,
        oi.l_quantity,
        oi.l_discount
    FROM 
        RankedParts rp
    JOIN 
        SupplierInfo si ON rp.p_brand = si.s_name
    JOIN 
        OrderInfo oi ON oi.l_quantity > 5 AND rp.p_retailprice < oi.o_totalprice
    WHERE 
        rp.rn <= 5
)
SELECT 
    fb.p_name,
    fb.p_brand,
    fb.p_retailprice,
    fb.s_name,
    fb.nation_name,
    fb.o_totalprice,
    fb.o_orderdate,
    fb.l_quantity,
    fb.l_discount,
    CONCAT('Item: ', fb.p_name, ', Brand: ', fb.p_brand, ', Price: ', fb.p_retailprice) AS item_details
FROM 
    FinalBenchmark fb
ORDER BY 
    fb.p_retailprice DESC, fb.o_totalprice ASC;