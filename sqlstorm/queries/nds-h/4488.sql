WITH SupplierOrderSummary AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(l.l_quantity) AS avg_quantity,
        RANK() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
), 
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    soss.s_name,
    soss.total_revenue,
    soss.order_count,
    coalesce(cod.total_sales, 0) AS customer_total_sales,
    coalesce(cod.order_count, 0) AS customer_order_count,
    cod.last_order_date,
    CASE 
        WHEN soss.revenue_rank = 1 THEN 'Top Revenue Supplier'
        ELSE 'Regular Supplier'
    END AS supplier_status
FROM 
    SupplierOrderSummary soss
LEFT JOIN 
    CustomerOrderDetails cod ON soss.s_suppkey = cod.c_custkey
WHERE 
    soss.total_revenue > 50000
ORDER BY 
    soss.total_revenue DESC
LIMIT 10;