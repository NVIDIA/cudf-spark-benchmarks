WITH SupplierProfit AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        (SUM(l.l_extendedprice * (1 - l.l_discount)) - SUM(ps.ps_supplycost * ps.ps_availqty)) AS profit
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sp.profit
    FROM SupplierProfit sp
    JOIN supplier s ON s.s_suppkey = sp.s_suppkey
    WHERE sp.profit > 0
    ORDER BY sp.profit DESC
    LIMIT 10
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice) AS total_price,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_net_price,
        MAX(o.o_orderdate) AS last_order_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    ts.s_name,
    ts.profit,
    od.total_quantity,
    od.total_price,
    od.total_net_price,
    od.last_order_date
FROM TopSuppliers ts
JOIN OrderDetails od ON ts.s_suppkey = od.o_orderkey
ORDER BY ts.profit DESC, od.total_net_price DESC;
