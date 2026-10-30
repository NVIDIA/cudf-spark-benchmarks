WITH TotalSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS sales_amount,
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
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        ts.s_suppkey,
        ts.s_name,
        ts.sales_amount,
        ts.order_count,
        RANK() OVER (ORDER BY ts.sales_amount DESC) AS rank
    FROM 
        TotalSales ts
)
SELECT 
    r.r_name,
    COUNT(DISTINCT ts.s_suppkey) AS supplier_count,
    SUM(ts.sales_amount) AS total_sales,
    AVG(ts.order_count) AS avg_orders_per_supplier
FROM 
    TopSuppliers ts
JOIN 
    supplier s ON ts.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    ts.rank <= 10
GROUP BY 
    r.r_name
ORDER BY 
    total_sales DESC;