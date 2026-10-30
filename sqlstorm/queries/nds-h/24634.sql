
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_comment,
        CASE 
            WHEN p.p_size IS NULL OR p.p_size < 5 THEN 'Small'
            WHEN p.p_size BETWEEN 5 AND 10 THEN 'Medium'
            ELSE 'Large'
        END AS size_category
    FROM 
        part p
    WHERE 
        p.p_retailprice BETWEEN (SELECT AVG(ps.ps_supplycost) FROM partsupp ps) * 0.8 
        AND (SELECT AVG(ps.ps_supplycost) FROM partsupp ps) * 1.2
),
CustomerPurchaseSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        c.c_custkey
),
MonthlyOrders AS (
    SELECT 
        DATE_TRUNC('month', o.o_orderdate) AS month,
        COUNT(*) AS orders_count,
        SUM(o.o_totalprice) AS month_revenue
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        DATE_TRUNC('month', o.o_orderdate)
),
HighlyActiveCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COALESCE(sum_orders.total_orders, 0) AS total_orders,
        COALESCE(sum_orders.total_spent, 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        CustomerPurchaseSummary sum_orders ON c.c_custkey = sum_orders.c_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 500
)
SELECT 
    f.p_name,
    f.p_retailprice,
    f.size_category,
    rs.s_name,
    rs.s_acctbal,
    ms.orders_count,
    ms.month_revenue,
    hac.c_name AS active_customer_name,
    hac.total_orders AS active_customer_orders,
    hac.total_spent AS active_customer_spent
FROM 
    FilteredParts f
JOIN 
    partsupp ps ON ps.ps_partkey = f.p_partkey
JOIN 
    RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey AND rs.rank = 1
LEFT JOIN 
    MonthlyOrders ms ON ms.orders_count > 10 
LEFT JOIN 
    HighlyActiveCustomers hac ON hac.total_orders > 5
WHERE 
    (f.p_retailprice IS NOT NULL AND f.p_retailprice > 100)
    OR (f.p_comment LIKE '%fragile%' AND hac.c_acctbal < 1000)
ORDER BY 
    ms.month_revenue DESC, 
    f.p_name;
