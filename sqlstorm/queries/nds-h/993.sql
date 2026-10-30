WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
TotalSales AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        l.l_suppkey
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ts.total_sales,
        COALESCE(ts.total_sales, 0) AS adjusted_sales
    FROM 
        RankedSuppliers s
    LEFT JOIN 
        TotalSales ts ON s.s_suppkey = ts.l_suppkey
    WHERE 
        s.rank <= 3
),
CustomerSummary AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
)
SELECT 
    r.r_name,
    ss.s_name,
    ss.adjusted_sales,
    cs.total_orders,
    cs.total_revenue
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierSales ss ON n.n_nationkey = ss.s_suppkey
LEFT JOIN 
    CustomerSummary cs ON n.n_nationkey = cs.c_nationkey
WHERE 
    r.r_name IS NOT NULL
ORDER BY 
    r.r_name, ss.adjusted_sales DESC;