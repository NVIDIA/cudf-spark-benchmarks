WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank,
        CASE 
            WHEN p.p_size IS NULL THEN 'Unknown'
            WHEN p.p_size BETWEEN 1 AND 10 THEN 'Small'
            WHEN p.p_size BETWEEN 11 AND 20 THEN 'Medium'
            ELSE 'Large'
        END AS size_category,
        p.p_comment
    FROM 
        part p
    WHERE 
        p.p_mfgr IN ('ManufacturerA', 'ManufacturerB')
), SupplierOrderCount AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    GROUP BY 
        s.s_suppkey
), RegionNation AS (
    SELECT 
        n.n_nationkey,
        r.r_regionkey,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_nationkey, r.r_regionkey
    HAVING 
        COUNT(DISTINCT n.n_name) > 1
), TotalSuppliers AS (
    SELECT 
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        SUM(CASE WHEN s.s_comment LIKE '%fragile%' THEN 1 ELSE 0 END) AS fragile_suppliers
    FROM 
        supplier s
    WHERE 
        s.s_phone IS NOT NULL AND LENGTH(s.s_phone) = 12
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_retailprice,
    rp.size_category,
    soc.order_count,
    RNC.r_regionkey,
    ts.total_suppliers,
    ts.fragile_suppliers,
    CASE
        WHEN soc.order_count IS NULL THEN 'No Orders'
        WHEN soc.order_count > 5 THEN 'Frequent Supplier'
        ELSE 'Infrequent Supplier'
    END AS supplier_status
FROM 
    RankedParts rp
LEFT JOIN 
    SupplierOrderCount soc ON rp.p_partkey = soc.s_suppkey
JOIN 
    RegionNation RNC ON RNC.n_nationkey = (SELECT MIN(n_nationkey) FROM nation)
CROSS JOIN 
    TotalSuppliers ts
WHERE 
    rp.rank <= 5 
    AND (rp.p_retailprice > 50 OR rp.size_category = 'Large')
ORDER BY 
    rp.p_retailprice DESC, 
    soc.order_count DESC
LIMIT 100;
