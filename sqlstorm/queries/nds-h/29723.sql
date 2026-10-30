
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        LENGTH(p.p_name) AS name_length,
        SUBSTRING(p.p_comment, 1, 10) AS comment_excerpt,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p 
    WHERE 
        p.p_type LIKE '%metal%'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        REPLACE(s.s_comment, 'supply', 'provision') AS refined_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000 AND LENGTH(s.s_name) > 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_mktsegment
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    rp.name_length,
    rp.comment_excerpt,
    sd.s_name AS supplier_name,
    co.c_name AS customer_name,
    co.order_count,
    co.last_order_date
FROM 
    RankedParts rp
JOIN 
    SupplierDetails sd ON sd.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE '%USA%')
JOIN 
    CustomerOrders co ON co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
WHERE 
    rp.brand_rank <= 5
ORDER BY 
    rp.name_length DESC, co.last_order_date DESC;
