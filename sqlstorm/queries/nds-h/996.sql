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
    WHERE 
        l.l_shipdate >= '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s_suppkey,
        s_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS rank
    FROM 
        SupplierSales
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
    r.r_name AS region,
    ns.n_name AS nation,
    COALESCE(ts.s_name, 'Unknown Supplier') AS top_supplier,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(co.order_count, 0) AS customer_order_count,
    COALESCE(co.total_spent, 0) AS total_customer_spent
FROM 
    region r
JOIN 
    nation ns ON ns.n_regionkey = r.r_regionkey
LEFT JOIN 
    TopSuppliers ts ON ts.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_type LIKE '%metal%'))
LEFT JOIN 
    CustomerOrders co ON ns.n_nationkey = co.c_custkey
WHERE 
    r.r_comment IS NOT NULL
ORDER BY 
    r.r_name, total_sales DESC;