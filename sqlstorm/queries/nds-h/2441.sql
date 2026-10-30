WITH SupplierRevenue AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1995-01-01' 
        AND l.l_shipdate <= DATE '1995-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
), CustomerOrderCount AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (ORDER BY sr.total_revenue DESC) AS supplier_rank
    FROM 
        SupplierRevenue sr
    JOIN 
        supplier s ON sr.s_suppkey = s.s_suppkey
    WHERE 
        sr.total_revenue > 5000
), TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        cc.order_count,
        RANK() OVER (ORDER BY cc.order_count DESC) AS customer_rank
    FROM 
        CustomerOrderCount cc
    JOIN 
        customer c ON cc.c_custkey = c.c_custkey
    WHERE 
        cc.order_count > 10
)
SELECT 
    ts.s_name AS top_supplier, 
    tc.c_name AS top_customer, 
    ts.supplier_rank,
    tc.customer_rank 
FROM 
    TopSuppliers ts 
FULL OUTER JOIN 
    TopCustomers tc ON ts.supplier_rank = tc.customer_rank
WHERE 
    ts.supplier_rank IS NOT NULL 
    OR tc.customer_rank IS NOT NULL
ORDER BY 
    COALESCE(ts.supplier_rank, 999), 
    COALESCE(tc.customer_rank, 999);