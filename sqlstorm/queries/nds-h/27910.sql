WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_brand
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%steel%'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        CONCAT(s.s_name, ' - ', s.s_address) AS supplier_details
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_totalprice
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    rp.p_comment,
    si.supplier_details,
    os.total_quantity,
    os.o_totalprice
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
JOIN 
    OrderSummary os ON ps.ps_partkey = os.o_orderkey
WHERE 
    rp.rank_brand <= 5
ORDER BY 
    rp.p_retailprice DESC;
