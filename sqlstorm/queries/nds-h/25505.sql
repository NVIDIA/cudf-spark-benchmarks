WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY LENGTH(p.p_name) DESC) as rank_name_length
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
), SupplierData AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal > 10000 THEN 'High'
            WHEN s.s_acctbal BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS acctbal_category
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), OrdersWithCounts AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS lineitem_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_type,
    rp.p_container,
    sd.s_name AS supplier_name,
    sd.supplier_nation,
    sd.acctbal_category,
    oc.o_orderdate,
    oc.lineitem_count,
    rp.p_comment
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierData sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    OrdersWithCounts oc ON oc.o_orderkey = ps.ps_partkey 
WHERE 
    rp.rank_name_length <= 5 
    AND sd.acctbal_category = 'High'
ORDER BY 
    rp.p_brand, oc.o_orderdate DESC;