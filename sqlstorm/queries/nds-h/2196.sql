
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        s.s_nationkey,
        s.s_suppkey,
        s.s_name,
        tt.total_sales
    FROM 
        supplier s
    INNER JOIN SupplierSales tt ON s.s_suppkey = tt.s_suppkey
    WHERE 
        tt.sales_rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    ts.s_name,
    ts.total_sales,
    co.c_name,
    co.order_count,
    co.total_spent
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    TopSuppliers ts ON n.n_nationkey = ts.s_nationkey
LEFT JOIN 
    CustomerOrders co ON ts.s_suppkey = co.c_custkey
WHERE 
    ts.total_sales IS NOT NULL AND 
    (co.total_spent IS NULL OR co.total_spent > 1000)
ORDER BY 
    r.r_name, ts.total_sales DESC;
