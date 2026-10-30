WITH SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sr.total_revenue,
        RANK() OVER (ORDER BY sr.total_revenue DESC) AS revenue_rank
    FROM 
        SupplierRevenue sr
    JOIN 
        supplier s ON sr.s_suppkey = s.s_suppkey
),
HighRevenueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        r.revenue_rank
    FROM 
        RankedSuppliers r
    JOIN 
        supplier s ON r.s_suppkey = s.s_suppkey
    WHERE 
        r.revenue_rank <= 10 AND 
        s.s_acctbal IS NOT NULL
)
SELECT 
    h.s_name AS supplier_name,
    h.s_acctbal AS account_balance,
    COALESCE(r.total_revenue, 0) AS total_revenue,
    CASE 
        WHEN h.s_acctbal > 50000 THEN 'High'
        WHEN h.s_acctbal BETWEEN 20000 AND 50000 THEN 'Medium'
        ELSE 'Low'
    END AS account_balance_category
FROM 
    HighRevenueSuppliers h
LEFT OUTER JOIN 
    SupplierRevenue r ON h.s_suppkey = r.s_suppkey
ORDER BY 
    h.s_name;