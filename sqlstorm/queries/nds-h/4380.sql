
WITH SupplierCost AS (
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
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_linenumber) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    n.n_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(os.total_order_value) AS total_revenue,
    AVG(COALESCE(sc.total_supply_cost, 0)) AS average_supplier_cost,
    MAX(os.item_count) AS max_items_per_order
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierCost sc ON s.s_suppkey = sc.s_suppkey
LEFT JOIN 
    OrderSummary os ON s.s_suppkey = os.o_orderkey
LEFT JOIN 
    orders o ON s.s_suppkey = o.o_orderkey
WHERE 
    n.n_name IS NOT NULL AND n.n_name <> 'USA'
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC, n.n_name ASC;
