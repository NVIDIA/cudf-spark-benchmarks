WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueOrders AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_value,
        COUNT(l.l_linenumber) AS line_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
)
SELECT 
    c.c_name,
    c.order_count,
    c.avg_order_value,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    s.total_supply_cost,
    CASE 
        WHEN s.total_supply_cost IS NULL THEN 'No Supply'
        WHEN s.total_supply_cost > 5000 THEN 'High Supply'
        ELSE 'Normal Supply'
    END AS supply_category,
    hvo.net_value,
    hvo.line_count
FROM 
    CustomerOrderStats c
LEFT JOIN 
    RankedSuppliers s ON c.c_custkey = s.s_suppkey
LEFT JOIN 
    HighValueOrders hvo ON hvo.l_orderkey = c.c_custkey
WHERE 
    (c.order_count > 5 AND c.avg_order_value < 300) OR (hvo.net_value IS NOT NULL)
ORDER BY 
    c.avg_order_value DESC, s.total_supply_cost ASC, supply_category;
