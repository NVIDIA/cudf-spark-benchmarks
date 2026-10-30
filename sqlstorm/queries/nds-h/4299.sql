
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 MONTH'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    p.p_brand,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(cos.total_spent) AS avg_customer_spent,
    COUNT(DISTINCT c.c_custkey) AS new_customers_count,
    MAX(ss.total_available_qty) AS max_supplier_qty,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    lineitem l
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    RankedOrders ro ON l.l_orderkey = ro.o_orderkey
LEFT JOIN 
    CustomerOrderSummary cos ON cos.order_count > 0
LEFT JOIN 
    SupplierStats ss ON ps.ps_suppkey = ss.s_suppkey
LEFT JOIN 
    customer c ON l.l_orderkey = ro.o_orderkey
WHERE 
    l.l_shipdate >= '1997-01-01' AND ro.order_rank <= 100
GROUP BY 
    p.p_name, p.p_brand, cos.total_spent, ss.total_available_qty
HAVING 
    COUNT(DISTINCT ro.o_orderkey) > 10
ORDER BY 
    total_revenue DESC;
