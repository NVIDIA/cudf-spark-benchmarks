WITH MonthlySales AS (
    SELECT 
        DATE_TRUNC('month', o_orderdate) AS sale_month,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales,
        COUNT(DISTINCT o_orderkey) AS order_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        sale_month
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_costs
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s_name,
        supplier_costs,
        ROW_NUMBER() OVER (ORDER BY supplier_costs DESC) AS rank
    FROM 
        SupplierDetails
),
SalesComparison AS (
    SELECT 
        ms.sale_month,
        ms.total_sales,
        ts.s_name AS top_supplier,
        ts.supplier_costs
    FROM 
        MonthlySales ms
    LEFT JOIN 
        TopSuppliers ts ON ms.sale_month = DATE_TRUNC('month', cast('1998-10-01' as date)) 
)
SELECT 
    sc.sale_month,
    sc.total_sales,
    COALESCE(sc.top_supplier, 'None') AS top_supplier,
    COALESCE(sc.supplier_costs, 0) AS supplier_costs,
    CASE 
        WHEN sc.total_sales > 100000 THEN 'High'
        WHEN sc.total_sales BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    SalesComparison sc
ORDER BY 
    sc.sale_month DESC;