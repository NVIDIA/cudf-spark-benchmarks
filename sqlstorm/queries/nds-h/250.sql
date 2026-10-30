WITH SupplierSales AS (
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
        s_suppkey,
        s_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SupplierSales
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
        o.o_orderstatus
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
HighValueOrders AS (
    SELECT 
        od.o_orderkey,
        od.o_orderdate,
        od.order_total,
        od.o_orderstatus
    FROM 
        OrderDetails od
    WHERE 
        od.order_total > (SELECT AVG(order_total) FROM OrderDetails)
)
SELECT 
    t.s_name,
    t.total_sales,
    h.o_orderkey,
    h.o_orderdate,
    h.order_total
FROM 
    TopSuppliers t
FULL OUTER JOIN 
    HighValueOrders h ON t.s_suppkey = h.o_orderkey
WHERE 
    (t.total_sales IS NOT NULL OR h.order_total IS NOT NULL)
ORDER BY 
    COALESCE(t.total_sales, 0) DESC, 
    COALESCE(h.order_total, 0) DESC;
