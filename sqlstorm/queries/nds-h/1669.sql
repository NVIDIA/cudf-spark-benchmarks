WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
CustomerStatistics AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    rp.o_orderkey,
    cs.total_orders,
    cs.total_spent,
    COALESCE(sp.total_availqty, 0) AS total_availqty,
    COALESCE(sp.avg_supplycost, 0.00) AS avg_supplycost,
    CASE 
        WHEN cs.total_orders > 10 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    part p
LEFT JOIN 
    RankedOrders rp ON p.p_partkey = rp.o_orderkey
LEFT JOIN 
    SupplierParts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN 
    CustomerStatistics cs ON rp.o_orderkey = cs.total_orders
WHERE 
    p.p_container LIKE '%BOX%'
    AND (sp.avg_supplycost IS NULL OR sp.avg_supplycost < 50)
    AND cs.total_spent > 1000
ORDER BY 
    total_spent DESC, p.p_name ASC;