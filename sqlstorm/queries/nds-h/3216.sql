
WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        o.o_orderpriority
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderpriority
), 
HighValueOrders AS (
    SELECT 
        o.o_orderdate AS order_date,
        COUNT(o.o_orderkey) AS high_value_order_count,
        SUM(od.revenue) AS total_revenue
    FROM 
        OrderDetails od
    JOIN 
        orders o ON od.o_orderkey = o.o_orderkey
    WHERE 
        od.revenue > 10000
    GROUP BY 
        o.o_orderdate
)
SELECT 
    r.r_name,
    np.n_name,
    sp.total_supply_cost,
    hvo.high_value_order_count,
    hvo.total_revenue,
    CASE 
        WHEN hvo.high_value_order_count IS NULL THEN 'No Orders'
        ELSE 'Orders Found'
    END AS order_status
FROM 
    region r
LEFT JOIN 
    nation np ON r.r_regionkey = np.n_regionkey
LEFT JOIN 
    SupplierParts sp ON np.n_nationkey = sp.s_suppkey
LEFT JOIN 
    HighValueOrders hvo ON hvo.order_date = DATE('1998-10-01')
WHERE 
    sp.total_supply_cost > 50000
ORDER BY 
    sp.total_supply_cost DESC, 
    hvo.total_revenue DESC;
