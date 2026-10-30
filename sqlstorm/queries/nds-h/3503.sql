WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        SUM(l.l_quantity) AS total_quantity_ordered,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name
    FROM 
        SupplierStats ss
    WHERE 
        ss.total_avail_qty > (SELECT AVG(total_avail_qty) FROM SupplierStats)
),
RecentOrders AS (
    SELECT 
        od.o_orderkey,
        od.o_orderdate,
        od.total_order_value,
        od.total_quantity_ordered
    FROM 
        OrderDetails od
    WHERE 
        od.order_rank = 1 AND od.total_order_value > 1000
)
SELECT 
    r.r_name,
    COALESCE(SUM(ro.total_order_value), 0) AS total_order_value,
    COALESCE(SUM(ro.total_quantity_ordered), 0) AS total_quantity_ordered,
    COUNT(DISTINCT ts.s_suppkey) AS active_suppliers,
    MAX(ss.avg_supply_cost) AS max_avg_supply_cost,
    CASE 
        WHEN SUM(ro.total_order_value) > 5000 THEN 'High Value'
        WHEN SUM(ro.total_order_value) BETWEEN 2000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS order_value_category
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    TopSuppliers ts ON s.s_suppkey = ts.s_suppkey
LEFT JOIN 
    RecentOrders ro ON s.s_suppkey = ro.o_orderkey
LEFT JOIN 
    SupplierStats ss ON ts.s_suppkey = ss.s_suppkey
GROUP BY 
    r.r_name
ORDER BY 
    total_order_value DESC, r.r_name;
