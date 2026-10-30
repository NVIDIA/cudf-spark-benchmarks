WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type
),
Popularity AS (
    SELECT 
        rp.p_partkey, 
        rp.p_name, 
        rp.p_mfgr, 
        rp.p_brand, 
        rp.p_type, 
        rp.supplier_count,
        ROW_NUMBER() OVER (ORDER BY rp.supplier_count DESC) AS rank
    FROM 
        RankedParts rp
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.s_phone, 
        p.p_brand, 
        p.p_type
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    p.p_name AS part_name, 
    s.s_name AS supplier_name, 
    s.s_address AS supplier_address,
    p.p_brand,
    p.p_type,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_discount) AS avg_discount
FROM 
    Popularity p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    SupplierDetails s ON p.p_brand = s.p_brand AND p.p_type = s.p_type
WHERE 
    p.rank <= 10
GROUP BY 
    p.p_name, s.s_name, s.s_address, p.p_brand, p.p_type
ORDER BY 
    order_count DESC, avg_discount DESC;
