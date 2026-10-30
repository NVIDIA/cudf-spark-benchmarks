
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
FinalReport AS (
    SELECT 
        R.o_orderkey,
        R.o_orderdate,
        COALESCE(S.total_sales, 0) AS supplier_sales,
        RANK() OVER (ORDER BY COALESCE(S.total_sales, 0) DESC) AS sales_rank
    FROM 
        RankedOrders R
    LEFT JOIN 
        SupplierSales S ON R.o_orderkey = S.s_suppkey
    WHERE 
        R.order_rank <= 10
)
SELECT 
    F.o_orderkey,
    F.o_orderdate,
    F.supplier_sales,
    CASE 
        WHEN H.s_suppkey IS NOT NULL THEN 'High Value Supplier'
        ELSE 'Other Supplier'
    END AS supplier_type
FROM 
    FinalReport F
LEFT JOIN 
    HighValueSuppliers H ON F.o_orderkey = H.s_suppkey
WHERE 
    F.supplier_sales IS NOT NULL
ORDER BY 
    F.supplier_sales DESC;
