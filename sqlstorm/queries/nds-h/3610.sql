
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_linenumber) AS total_items
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, c.c_custkey
),
RankedOrders AS (
    SELECT 
        od.o_orderkey,
        od.total_order_value,
        od.total_items,
        RANK() OVER (ORDER BY od.total_order_value DESC) AS order_rank
    FROM OrderDetails od
)
SELECT 
    rs.s_name,
    rs.total_available_qty,
    roo.total_order_value,
    ro.total_items,
    ro.order_rank,
    CASE 
        WHEN roo.total_order_value IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status
FROM SupplierStats rs
LEFT JOIN RankedOrders ro ON rs.s_suppkey = (SELECT ps.ps_suppkey 
                                               FROM partsupp ps 
                                               WHERE ps.ps_partkey IN (SELECT p.p_partkey 
                                                                       FROM part p 
                                                                       WHERE p.p_brand = 'BrandX'))
LEFT JOIN RankedOrders roo ON roo.o_orderkey = ro.o_orderkey
WHERE rs.total_supply_cost > 50000 
ORDER BY rs.total_available_qty DESC, ro.order_rank;
