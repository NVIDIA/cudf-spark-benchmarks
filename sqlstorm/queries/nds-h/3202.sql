
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
NationSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        n.n_nationkey, n.n_name
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_shipdate >= o.o_orderdate AND l.l_shipdate <= o.o_orderdate + INTERVAL '30 days'
    GROUP BY 
        s.s_suppkey
),
SalesComparison AS (
    SELECT 
        ns.n_nationkey,
        ns.n_name,
        COALESCE(ss.supplier_total_sales, 0) AS supplier_sales,
        ns.total_sales
    FROM 
        NationSales ns
    LEFT JOIN 
        SupplierSales ss ON ns.n_nationkey = ss.s_suppkey
)

SELECT 
    sc.n_name,
    sc.total_sales,
    sc.supplier_sales,
    CASE 
        WHEN sc.total_sales > 0 THEN (sc.supplier_sales / sc.total_sales) * 100
        ELSE NULL 
    END AS supplier_sales_percentage,
    rs.s_name AS top_supplier_name,
    rs.s_acctbal AS top_supplier_acct_bal
FROM 
    SalesComparison sc
LEFT JOIN 
    RankedSuppliers rs ON sc.n_nationkey = rs.s_suppkey AND rs.rank = 1
WHERE 
    COALESCE(rs.s_acctbal, 0) > 1000
ORDER BY 
    sc.total_sales DESC, supplier_sales_percentage DESC;
