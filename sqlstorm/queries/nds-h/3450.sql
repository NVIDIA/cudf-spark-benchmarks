WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerActivity AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.total_revenue,
    COALESCE(sa.total_supply_cost, 0) AS supplier_cost,
    ca.order_count,
    ca.total_spent,
    CASE 
        WHEN ca.total_spent IS NULL THEN 'No Orders'
        WHEN ca.order_count > 10 THEN 'High Activity'
        ELSE 'Low Activity'
    END AS customer_activity_level
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierSummary sa ON r.o_orderkey % (SELECT COUNT(su.s_suppkey) FROM supplier su) = sa.s_suppkey
LEFT JOIN 
    CustomerActivity ca ON r.o_orderkey = ca.c_custkey
WHERE 
    rnk <= 5
ORDER BY 
    r.total_revenue DESC,
    r.o_orderdate ASC;