
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_supply_cost
    FROM 
        SupplierSales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.total_supply_cost > (
            SELECT AVG(total_supply_cost) 
            FROM SupplierSales
        )
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    r.total_revenue,
    CASE 
        WHEN r.rn = 1 THEN 'Latest Order' 
        ELSE 'Prior Order' 
    END AS order_status,
    COALESCE(h.total_supply_cost, 0) AS high_value_cost
FROM 
    RankedOrders r 
LEFT JOIN 
    HighValueSuppliers h ON r.o_orderkey = h.s_suppkey
LEFT JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
WHERE 
    r.total_revenue > 1000.00
ORDER BY 
    r.total_revenue DESC, r.o_orderdate;
