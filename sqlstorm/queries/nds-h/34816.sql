WITH  SalesData AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice) AS supplier_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
), TotalSales AS (
    SELECT 
        SUM(total_sales) AS grand_total_sales
    FROM 
        SalesData
)
SELECT 
    sd.o_orderkey,
    sd.o_orderdate,
    sd.total_sales,
    ss.s_name,
    ss.supplier_sales,
    ts.grand_total_sales,
    COALESCE(ss.order_count, 0) AS order_count
FROM 
    SalesData sd
LEFT JOIN 
    SupplierSales ss ON sd.o_orderkey = ss.order_count
CROSS JOIN 
    TotalSales ts
WHERE 
    sd.total_sales > (SELECT AVG(total_sales) FROM SalesData)
ORDER BY 
    sd.o_orderdate DESC;