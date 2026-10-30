WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS returns_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        l.l_shipdate >= '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SupplierPerformance
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(l.l_quantity) AS avg_quantity_per_order
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ts.s_name AS supplier_name,
    ts.total_sales,
    cs.c_name AS customer_name,
    cs.total_spent,
    cs.total_orders,
    cs.avg_quantity_per_order
FROM 
    TopSuppliers ts
FULL OUTER JOIN 
    CustomerSales cs ON ts.sales_rank = 1 AND cs.total_spent > 0
WHERE 
    (ts.total_sales IS NOT NULL AND cs.total_spent IS NOT NULL)
ORDER BY 
    ts.total_sales DESC, cs.total_spent DESC
LIMIT 100;