WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_comment,
        CONCAT(s.s_name, ' (', n.n_name, ' - ', r.r_name, ')') AS full_supplier_info
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name, 
        p.p_retailprice,
        p.p_comment,
        CASE 
            WHEN p.p_size < 10 THEN 'Small'
            WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium'
            ELSE 'Large'
        END AS size_category
    FROM 
        part p
),
JoinedData AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice,
        s.full_supplier_info,
        p.p_name,
        p.size_category
    FROM 
        lineitem l
    JOIN 
        SupplierDetails s ON l.l_suppkey = s.s_suppkey
    JOIN 
        PartDetails p ON l.l_partkey = p.p_partkey
)
SELECT 
    jd.l_orderkey,
    SUM(jd.l_extendedprice * jd.l_quantity * 0.9) AS discounted_price,
    jd.size_category,
    COUNT(DISTINCT jd.full_supplier_info) AS unique_suppliers
FROM 
    JoinedData jd
WHERE 
    jd.l_quantity > 5
GROUP BY 
    jd.l_orderkey, 
    jd.size_category
ORDER BY 
    discounted_price DESC, 
    jd.size_category;
