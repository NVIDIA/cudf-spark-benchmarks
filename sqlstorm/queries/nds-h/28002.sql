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
        p.p_name LIKE '%widget%'
), SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 1000
), OrderInfo AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(DISTINCT l.l_linenumber) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    COUNT(DISTINCT si.s_suppkey) AS supplier_count,
    SUM(oi.total_quantity) AS total_ordered_quantity,
    AVG(oi.o_totalprice) AS avg_order_price
FROM 
    RankedParts rp
LEFT JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
LEFT JOIN 
    OrderInfo oi ON ps.ps_partkey = oi.o_orderkey
WHERE 
    rp.rn <= 10
GROUP BY 
    rp.p_name, rp.p_brand, rp.p_retailprice
ORDER BY 
    rp.p_retailprice DESC;