
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        CASE WHEN s.s_acctbal IS NULL THEN 'No balance' ELSE 'Has balance' END AS balance_status
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
)
SELECT 
    p.p_name,
    r.r_name,
    n.n_name,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales,
    CASE WHEN COUNT(l.l_orderkey) > 0 THEN 'Sold' ELSE 'Unsold' END AS sales_status,
    sd.balance_status,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    SupplierDetails sd ON s.s_suppkey = sd.s_suppkey
WHERE 
    (r.r_name IS NOT NULL OR n.n_name IS NOT NULL) 
    AND p.p_retailprice IS NOT NULL
GROUP BY 
    p.p_name, r.r_name, n.n_name, sd.balance_status
HAVING 
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) > 1000.00
ORDER BY 
    total_sales DESC, p.p_name ASC;
