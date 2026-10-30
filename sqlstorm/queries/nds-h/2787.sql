
WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
)
SELECT 
    n.n_name AS nation,
    ss.s_name AS supplier_name,
    ss.total_available_quantity,
    ss.average_supply_cost,
    ro.o_orderkey,
    ro.o_totalprice,
    CASE 
        WHEN ro.o_totalprice > 1000 THEN 'High Value'
        ELSE 'Standard Value'
    END AS order_value_category,
    COALESCE(MAX(l.l_discount), 0) AS max_discount
FROM 
    SupplierSummary ss
LEFT OUTER JOIN 
    lineitem l ON ss.s_suppkey = l.l_suppkey
LEFT OUTER JOIN 
    RecentOrders ro ON ro.o_custkey = ss.s_suppkey
JOIN 
    nation n ON ss.s_suppkey = n.n_nationkey
WHERE 
    ss.total_available_quantity IS NOT NULL
    AND (ss.average_supply_cost BETWEEN 50 AND 200 OR ss.total_available_quantity > 500)
GROUP BY 
    n.n_name, ss.s_name, ss.total_available_quantity, ss.average_supply_cost, ro.o_orderkey, ro.o_totalprice
HAVING 
    COUNT(DISTINCT ro.o_orderkey) > 1
ORDER BY 
    n.n_name, ss.s_name;
