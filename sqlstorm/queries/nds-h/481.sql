WITH RankedOrders AS (
    SELECT 
        o_orderkey, 
        o_custkey, 
        o_totalprice, 
        o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_totalprice DESC) AS rn
    FROM 
        orders
    WHERE 
        o_orderdate >= DATE '1997-01-01'
),
SupplierParts AS (
    SELECT 
        ps_partkey, 
        ps_suppkey, 
        SUM(ps_availqty) AS total_available_qty,
        AVG(ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp
    GROUP BY 
        ps_partkey, 
        ps_suppkey
),
CustomerOrderAggregates AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(o.o_totalprice), 0) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, 
        c.c_name
)
SELECT 
    c.c_custkey,
    c.c_name,
    COALESCE(ca.total_spent, 0) AS total_spent,
    ca.order_count,
    CASE 
        WHEN ca.last_order_date IS NOT NULL THEN 'Active'
        ELSE 'Inactive'
    END AS customer_status,
    COUNT(DISTINCT s.s_suppkey) AS number_of_suppliers,
    SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS total_revenue,
    AVG(lp.l_tax) AS avg_tax_rate
FROM 
    CustomerOrderAggregates ca
JOIN 
    customer c ON ca.c_custkey = c.c_custkey
LEFT JOIN 
    lineitem lp ON c.c_custkey = lp.l_orderkey
LEFT JOIN 
    supplier s ON lp.l_suppkey = s.s_suppkey
LEFT JOIN 
    SupplierParts sp ON lp.l_partkey = sp.ps_partkey
WHERE 
    c.c_acctbal IS NOT NULL
GROUP BY 
    c.c_custkey, 
    c.c_name, 
    ca.total_spent, 
    ca.order_count, 
    ca.last_order_date
HAVING 
    SUM(lp.l_extendedprice * (1 - lp.l_discount)) > 1000 
    OR ca.order_count > 10
ORDER BY 
    total_revenue DESC
LIMIT 100;