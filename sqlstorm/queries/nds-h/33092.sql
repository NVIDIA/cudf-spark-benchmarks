
WITH  RevenueCTE AS (
    SELECT 
        l_orderkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY l_orderkey ORDER BY l_orderkey) AS rn
    FROM 
        lineitem
    WHERE 
        l_shipdate >= DATE '1996-01-01'
    GROUP BY 
        l_orderkey
),
SupplierRank AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (ORDER BY SUM(ps_supplycost * ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    o.o_orderkey,
    c.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
    r.r_name AS region_name,
    sr.supplier_rank
FROM 
    orders o
JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    SupplierRank sr ON s.s_suppkey = sr.s_suppkey
WHERE 
    o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    AND (c.c_acctbal IS NOT NULL OR sr.supplier_rank <= 5)
GROUP BY 
    o.o_orderkey, c.c_name, r.r_name, sr.supplier_rank
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(total_revenue) FROM RevenueCTE WHERE rn = 1)
ORDER BY 
    total_order_value DESC
LIMIT 10;
