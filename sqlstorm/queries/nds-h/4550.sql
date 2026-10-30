WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate > DATE '1997-01-01'
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_sales,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        SupplierSales ss
    WHERE 
        ss.total_sales > 10000
),
FinalReport AS (
    SELECT 
        r.r_name,
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    INNER JOIN 
        TopSuppliers ts ON ts.s_suppkey = o.o_orderkey 
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    fr.r_name, 
    fr.n_name,
    fr.customer_count,
    fr.total_order_value,
    CASE 
        WHEN fr.total_order_value IS NULL THEN 'No Orders'
        WHEN fr.customer_count > 100 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS volume_status
FROM 
    FinalReport fr
WHERE 
    fr.customer_count IS NOT NULL
ORDER BY 
    fr.total_order_value DESC
LIMIT 10;