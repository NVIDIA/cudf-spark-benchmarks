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
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%steel%'
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        rp.p_partkey,
        rp.p_name
    FROM 
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN RankedParts rp ON ps.ps_partkey = rp.p_partkey
), 
SalesSummary AS (
    SELECT 
        c.c_name,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_name
)
SELECT 
    sd.s_name AS supplier_name,
    sd.s_address AS supplier_address,
    sd.s_phone AS supplier_phone,
    ss.c_name AS customer_name,
    ss.total_sales,
    ss.order_count,
    rp.p_name AS part_name,
    rp.p_retailprice AS retail_price
FROM 
    SupplierDetails sd
JOIN 
    SalesSummary ss ON sd.s_name = ss.c_name
JOIN 
    RankedParts rp ON sd.p_partkey = rp.p_partkey
WHERE 
    rp.rank <= 5
ORDER BY 
    ss.total_sales DESC, sd.s_name;
