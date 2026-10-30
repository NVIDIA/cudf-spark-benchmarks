WITH  SupplyRanks AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        PS.ps_availqty,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost) AS rank
    FROM 
        partsupp ps
),
TopSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s 
    JOIN 
        SupplyRanks sr ON s.s_suppkey = sr.ps_suppkey 
    JOIN 
        lineitem l ON sr.ps_partkey = l.l_partkey
    WHERE 
        sr.rank <= 3
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
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
    co.c_name,
    co.order_count,
    COALESCE(co.total_spent, 0) AS total_spent,
    ts.s_name AS top_supplier,
    ts.total_revenue,
    CASE 
        WHEN co.total_spent IS NULL OR co.total_spent = 0 THEN 'New Customer'
        WHEN co.total_spent < 5000 THEN 'Regular Customer'
        ELSE 'VIP Customer'
    END AS customer_status
FROM 
    CustomerOrders co
LEFT JOIN 
    TopSuppliers ts ON ts.total_revenue = (
        SELECT MAX(total_revenue) FROM TopSuppliers
    )
WHERE 
    co.order_count > 0
ORDER BY 
    co.total_spent DESC, co.c_name;
