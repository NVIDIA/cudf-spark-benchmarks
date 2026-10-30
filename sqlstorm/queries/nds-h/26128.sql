WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        LENGTH(p.p_comment) AS comment_length,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_by_price
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT ps.ps_availqty FROM partsupp ps WHERE ps.ps_supplycost < 100.00)
),
SuppliedParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_retailprice,
        rp.comment_length,
        s.s_name AS supplier_name,
        s.s_nationkey,
        n.n_name AS nation_name
    FROM 
        RankedParts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        rp.rank_by_price <= 5
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        c.c_name AS customer_name,
        rp.p_name
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        SuppliedParts rp ON l.l_partkey = rp.p_partkey
)
SELECT  
    sop.supplier_name,
    sop.nation_name,
    COUNT(co.o_orderkey) AS total_orders,
    SUM(co.o_totalprice) AS total_sales
FROM 
    SuppliedParts sop
LEFT JOIN 
    CustomerOrders co ON sop.p_name = co.p_name
GROUP BY 
    sop.supplier_name, sop.nation_name
ORDER BY 
    total_sales DESC
LIMIT 10;
