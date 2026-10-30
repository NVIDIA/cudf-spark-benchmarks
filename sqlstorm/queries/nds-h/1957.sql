WITH RankedSales AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        ROW_NUMBER() OVER (PARTITION BY l.l_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        l.l_orderkey, l.l_partkey, l.l_suppkey
),
SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(rs.net_revenue) AS total_revenue
    FROM 
        supplier s
    LEFT JOIN 
        RankedSales rs ON s.s_suppkey = rs.l_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        sr.s_suppkey, 
        sr.s_name,
        sr.total_revenue,
        RANK() OVER (ORDER BY sr.total_revenue DESC) AS rank_position
    FROM 
        SupplierRevenue sr
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    COALESCE(ts.total_revenue, 0) AS supplier_revenue,
    CASE 
        WHEN ts.rank_position IS NOT NULL THEN 'Top Supplier' 
        ELSE 'Other' 
    END AS supplier_status
FROM 
    part p
LEFT JOIN 
    TopSuppliers ts ON p.p_partkey = ts.s_suppkey
WHERE 
    p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100.00)
ORDER BY 
    p.p_partkey;