
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '12 months'
), 
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), 
CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    r.r_name AS region_name,
    s.s_name AS supplier_name,
    COALESCE(ss.total_available, 0) AS total_available,
    COALESCE(ss.avg_supply_cost, 0) AS avg_supply_cost,
    COALESCE(cp.total_spent, 0) AS total_spent,
    cp.total_orders,
    CASE 
        WHEN cp.total_spent > 1000 THEN 'High'
        WHEN cp.total_spent BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS spending_category
FROM 
    part p
LEFT JOIN 
    supplier s ON p.p_partkey = s.s_suppkey
LEFT JOIN 
    region r ON s.s_nationkey = r.r_regionkey
LEFT JOIN 
    SupplierStats ss ON p.p_partkey = ss.ps_partkey
LEFT JOIN 
    CustomerPurchases cp ON cp.c_custkey = s.s_suppkey
WHERE 
    (ss.total_available IS NULL OR ss.total_available > 50) 
    AND (p.p_retailprice > 100.00 OR p.p_comment LIKE '%high%')
GROUP BY 
    p.p_partkey,
    p.p_name,
    r.r_name,
    s.s_name,
    ss.total_available,
    ss.avg_supply_cost,
    cp.total_spent,
    cp.total_orders
ORDER BY 
    total_spent DESC, 
    region_name ASC, 
    supplier_name ASC;
