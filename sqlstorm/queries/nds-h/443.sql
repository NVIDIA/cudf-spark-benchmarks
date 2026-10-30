WITH TotalSales AS (
    SELECT 
        l_partkey, 
        SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
    FROM 
        lineitem
    WHERE 
        l_shipdate >= DATE '1997-01-01' 
        AND l_shipdate < DATE '1998-01-01'
    GROUP BY 
        l_partkey
),
TopSuppliers AS (
    SELECT 
        ps_suppkey, 
        SUM(ps_supplycost * ps_availqty) AS total_supplycost
    FROM 
        partsupp
    WHERE 
        ps_availqty > 100
    GROUP BY 
        ps_suppkey
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name,
        r.r_name,
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
RevenueAnalysis AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(ts.total_revenue, 0) AS total_revenue,
        COALESCE(ts.total_revenue / NULLIF(tps.total_supplycost, 0), 0) AS revenue_per_supplycost
    FROM 
        part p
    LEFT JOIN 
        TotalSales ts ON p.p_partkey = ts.l_partkey
    LEFT JOIN 
        TopSuppliers tps ON p.p_partkey = tps.ps_suppkey
)
SELECT 
    ra.p_partkey,
    ra.p_name,
    ra.total_revenue,
    ra.revenue_per_supplycost,
    si.s_name AS supplier_name
FROM 
    RevenueAnalysis ra
LEFT JOIN 
    SupplierInfo si ON ra.p_partkey = si.s_suppkey  
WHERE 
    ra.total_revenue > 1000
ORDER BY 
    ra.total_revenue DESC
LIMIT 10;