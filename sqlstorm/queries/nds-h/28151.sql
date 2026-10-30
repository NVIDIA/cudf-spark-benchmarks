WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        LENGTH(p.p_comment) AS comment_length,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY LENGTH(p.p_comment) DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_type LIKE '%rubber%' AND 
        p.p_retailprice > (SELECT AVG(p_retailprice) FROM part WHERE p_type LIKE '%rubber%')
),
SupplierCounts AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
Combined AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        sc.supplier_count,
        rp.comment_length
    FROM 
        RankedParts rp
    JOIN 
        SupplierCounts sc ON rp.p_partkey = sc.ps_partkey
    WHERE 
        rp.rank <= 5
)
SELECT 
    c.c_name AS customer_name,
    c.c_address AS customer_address,
    c.c_acctbal AS customer_account_balance,
    co.p_partkey,
    co.p_name,
    co.p_brand,
    co.supplier_count,
    co.comment_length
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    Combined co ON l.l_partkey = co.p_partkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
ORDER BY 
    co.supplier_count DESC, co.comment_length DESC;