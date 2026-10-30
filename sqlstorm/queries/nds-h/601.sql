WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_supply_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        MIN(l.l_shipdate) AS first_ship_date,
        MAX(l.l_shipdate) AS last_ship_date,
        COUNT(DISTINCT l.l_linenumber) AS number_of_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
    GROUP BY 
        o.o_orderkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_supply_quantity,
        ss.total_supply_cost
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.rank_within_nation <= 3
)
SELECT 
    od.o_orderkey,
    od.net_revenue,
    od.first_ship_date,
    od.last_ship_date,
    COUNT(DISTINCT ts.s_suppkey) AS unique_supplier_count,
    AVG(ts.total_supply_cost) AS avg_supplier_cost
FROM 
    OrderDetails od
LEFT JOIN 
    lineitem l ON od.o_orderkey = l.l_orderkey
LEFT JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
GROUP BY 
    od.o_orderkey, od.net_revenue, od.first_ship_date, od.last_ship_date
HAVING 
    AVG(ts.total_supply_cost) IS NOT NULL AND 
    COUNT(DISTINCT ts.s_suppkey) > 2
ORDER BY 
    net_revenue DESC
LIMIT 10;