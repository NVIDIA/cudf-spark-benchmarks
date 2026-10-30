WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY ps.ps_supplycost DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
CustomerTotalOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
SupplierInfo AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.ps_availqty,
        rs.ps_supplycost,
        ct.total_orders
    FROM RankedSuppliers rs
    LEFT JOIN CustomerTotalOrders ct ON ct.c_custkey = (
        SELECT o.o_custkey 
        FROM HighValueOrders h 
        JOIN orders o ON h.o_orderkey = o.o_orderkey
        WHERE h.o_custkey IS NOT NULL
        LIMIT 1
    )
    WHERE rs.rank = 1
)
SELECT 
    si.s_suppkey,
    si.s_name,
    si.ps_availqty,
    si.ps_supplycost,
    COALESCE(si.total_orders, 0) AS total_orders,
    CASE 
        WHEN si.total_orders > 500 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM SupplierInfo si
WHERE si.ps_availqty IS NOT NULL
ORDER BY si.ps_supplycost DESC, si.total_orders DESC;
