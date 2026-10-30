WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name, 
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s_acctbal)
            FROM supplier
        )
), 
LineItemSummary AS (
    SELECT 
        l.l_partkey,
        COUNT(l.l_orderkey) AS order_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' 
        AND l.l_shipdate <= DATE '1996-12-31'
    GROUP BY 
        l.l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(SUM(l.order_count), 0) AS total_orders,
    COALESCE(ROUND(SUM(l.total_revenue), 2), 0.00) AS revenue,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    COUNT(DISTINCT CASE WHEN s.s_acctbal IS NOT NULL THEN s.s_suppkey END) AS active_suppliers
FROM 
    part p
LEFT JOIN 
    LineItemSummary l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierInfo s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
HAVING 
    SUM(l.order_count) > 10
ORDER BY 
    revenue DESC
LIMIT 10;