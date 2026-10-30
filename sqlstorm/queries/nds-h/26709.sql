WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_type LIKE '%metal%' AND 
        p.p_retailprice > 100
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        LOWER(s.s_address) AS s_address_lower,
        s.s_phone,
        s.s_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        COUNT(DISTINCT l.l_orderkey) AS lineitem_count
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name
)
SELECT 
    rp.p_name,
    rp.p_brand,
    s.s_name AS supplier_name,
    s.s_phone,
    co.lineitem_count,
    co.o_totalprice
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    CustomerOrders co ON co.o_orderkey = ps.ps_partkey
WHERE 
    rp.rank <= 3
ORDER BY 
    rp.p_brand, rp.p_retailprice DESC, co.o_totalprice DESC;
