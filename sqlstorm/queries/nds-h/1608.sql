WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS total_items,
        AVG(l.l_quantity) AS avg_quantity
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
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    rs.s_name AS supplier_name,
    os.total_revenue,
    os.total_items,
    os.avg_quantity,
    COALESCE(region.r_name, 'Unknown') AS region_name,
    CASE 
        WHEN os.total_revenue IS NULL THEN 'No Sales'
        WHEN os.total_revenue > 5000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
LEFT JOIN 
    nation n ON rs.s_nationkey = n.n_nationkey
LEFT JOIN 
    region ON n.n_regionkey = region.r_regionkey
LEFT JOIN 
    OrderStats os ON p.p_partkey = os.o_orderkey 
WHERE 
    p.p_retailprice BETWEEN 10 AND 500 
    AND (n.n_name IS NULL OR n.n_name != 'USA')
ORDER BY 
    p.p_retailprice DESC, 
    revenue_category DESC;
