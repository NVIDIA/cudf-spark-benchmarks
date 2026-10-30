WITH SupplierOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
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
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
), RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        so.total_revenue,
        so.order_count,
        DENSE_RANK() OVER (ORDER BY so.total_revenue DESC) AS revenue_rank
    FROM 
        SupplierOrders so
    JOIN 
        supplier s ON so.s_suppkey = s.s_suppkey
), CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), HighValueCustomers AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.total_orders,
        cs.total_spent,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM 
        CustomerStats cs
    WHERE 
        cs.total_spent > 10000
)
SELECT 
    rs.s_name,
    rs.total_revenue,
    hvc.c_name AS high_value_customer,
    hvc.total_orders,
    hvc.total_spent
FROM 
    RankedSuppliers rs
FULL OUTER JOIN 
    HighValueCustomers hvc ON rs.revenue_rank = hvc.customer_rank
WHERE 
    rs.total_revenue IS NOT NULL OR hvc.total_spent IS NOT NULL
ORDER BY 
    COALESCE(rs.total_revenue, 0) DESC, 
    COALESCE(hvc.total_spent, 0) DESC;