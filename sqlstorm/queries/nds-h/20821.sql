
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
    HAVING 
        COUNT(DISTINCT ps.ps_suppkey) > 3
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    ns.r_name AS nation_name,
    SUM(os.total_revenue) AS total_revenue,
    AVG(p.p_retailprice) AS average_retail_price,
    MAX(s.s_acctbal) AS max_supplier_acctbal
FROM 
    region ns
LEFT JOIN 
    nation n ON ns.r_regionkey = n.n_regionkey 
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey 
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey AND rs.rnk = 1
FULL OUTER JOIN 
    HighValueParts p ON p.p_partkey = s.s_suppkey 
JOIN 
    OrderSummary os ON os.o_orderkey = p.p_partkey 
WHERE 
    ns.r_name IS NOT NULL 
    AND (s.s_acctbal IS NULL OR s.s_acctbal > 5000)
GROUP BY 
    ns.r_name
HAVING 
    COUNT(DISTINCT os.o_orderkey) > 10
ORDER BY 
    total_revenue DESC 
LIMIT 10;
