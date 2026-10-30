WITH TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    ORDER BY 
        total_supply_cost DESC
    LIMIT 10
), 
SalesData AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sale
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), 
SupplierSales AS (
    SELECT 
        ts.s_suppkey,
        ts.s_name,
        sd.total_sale
    FROM 
        TopSuppliers ts
    JOIN 
        partsupp ps ON ts.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        SalesData sd ON l.l_orderkey = sd.o_orderkey
)
SELECT 
    s.s_name,
    COUNT(DISTINCT ss.total_sale) AS unique_sales_count,
    AVG(ss.total_sale) AS avg_sales,
    SUM(ss.total_sale) AS total_sales
FROM 
    SupplierSales ss
JOIN 
    supplier s ON ss.s_suppkey = s.s_suppkey
GROUP BY 
    s.s_name
ORDER BY 
    total_sales DESC
LIMIT 5;