WITH SupplierStatistics AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_available_quantity DESC) AS rank_quantity
    FROM 
        SupplierStatistics
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        MAX(o.o_totalprice) AS max_order_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    t.s_name,
    t.total_available_quantity,
    o.total_revenue,
    o.max_order_price,
    COALESCE(t.total_available_quantity * o.total_revenue, 0) AS performance_metric
FROM 
    TopSuppliers t
LEFT JOIN 
    OrderSummary o ON t.rank_quantity <= 5
WHERE 
    t.total_available_quantity > 0
ORDER BY 
    performance_metric DESC
LIMIT 10;