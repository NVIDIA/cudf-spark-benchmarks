WITH CTE_SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CTE_HighSales AS (
    SELECT 
        *
    FROM 
        CTE_SupplierSales
    WHERE 
        total_sales > (SELECT AVG(total_sales) FROM CTE_SupplierSales)
),
CTE_CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    n.n_name,
    s.s_name,
    COALESCE(h.total_sales, 0) AS supplier_sales,
    COALESCE(c.order_count, 0) AS customer_order_count,
    COALESCE(c.total_spent, 0) AS customer_total_spent
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    CTE_HighSales h ON s.s_suppkey = h.s_suppkey
LEFT JOIN 
    CTE_CustomerOrders c ON s.s_suppkey = c.c_custkey
WHERE 
    r.r_name IS NOT NULL
ORDER BY 
    supplier_sales DESC, customer_total_spent DESC;
