
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
    GROUP BY 
        s.s_suppkey, s.s_name
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
    WHERE 
        c.c_acctbal > 100
    GROUP BY 
        c.c_custkey, c.c_name
),
HighRevenueSuppliers AS (
    SELECT 
        sr.s_suppkey,
        sr.s_name,
        sr.total_revenue
    FROM 
        SupplierRevenue sr
    WHERE 
        sr.total_revenue > (SELECT AVG(total_revenue) FROM SupplierRevenue)
),
HighSpendingCustomers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_spent
    FROM 
        CustomerOrders co
    WHERE 
        co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
)
SELECT 
    hs.s_name AS supplier_name,
    hc.c_name AS customer_name,
    hs.s_suppkey,
    hc.c_custkey,
    COALESCE(NULLIF(hs.total_revenue, 0), 1) / COALESCE(NULLIF(hc.total_spent, 0), 1) AS revenue_spent_ratio
FROM 
    HighRevenueSuppliers hs
FULL OUTER JOIN 
    HighSpendingCustomers hc ON hs.s_suppkey = hc.c_custkey
ORDER BY 
    revenue_spent_ratio DESC
LIMIT 50;
