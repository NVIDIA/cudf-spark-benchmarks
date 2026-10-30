WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS customer_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
NationSales AS (
    SELECT 
        n.n_name,
        SUM(os.total_revenue) AS total_sales
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        OrderSummary os ON o.o_orderkey = os.o_orderkey
    GROUP BY 
        n.n_name
)
SELECT 
    ns.n_name,
    COALESCE(ns.total_sales, 0) AS total_sales,
    si.s_name AS top_supplier,
    si.s_acctbal AS top_supplier_acctbal
FROM 
    NationSales ns
LEFT JOIN 
    SupplierInfo si ON ns.total_sales > 0 AND si.rn = 1
ORDER BY 
    total_sales DESC;
