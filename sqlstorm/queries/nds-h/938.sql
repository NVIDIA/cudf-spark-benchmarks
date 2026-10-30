
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
TotalSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE('1997-01-01') AND DATE('1997-12-31')
    GROUP BY 
        l.l_partkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_mfgr,
        COALESCE(ts.total_revenue, 0) AS total_revenue
    FROM 
        part p
    LEFT JOIN 
        TotalSales ts ON p.p_partkey = ts.l_partkey
),
SupplierInfo AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        pd.p_partkey,
        pd.total_revenue
    FROM 
        RankedSuppliers rs
    JOIN 
        PartDetails pd ON rs.rn = 1 AND rs.s_suppkey = pd.p_partkey
)
SELECT 
    pd.p_name,
    pd.p_brand,
    pd.p_mfgr,
    COALESCE(si.s_name, 'No Supplier') AS supplier_name,
    si.s_acctbal,
    pd.total_revenue,
    (CASE 
        WHEN pd.total_revenue > 10000 THEN 'High Revenue'
        WHEN pd.total_revenue BETWEEN 5000 AND 10000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END) AS revenue_category
FROM 
    PartDetails pd
LEFT JOIN 
    SupplierInfo si ON pd.p_partkey = si.p_partkey
ORDER BY 
    pd.total_revenue DESC
LIMIT 50;
