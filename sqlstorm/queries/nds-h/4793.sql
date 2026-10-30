
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
),
SupplierParts AS (
    SELECT 
        s.s_name,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 100
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 5000
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(sp.s_name, 'No Supplier') AS supplier_name,
    sp.p_name AS part_name,
    COALESCE(hc.total_spent, 0) AS total_spent_by_customer,
    'Order Status: ' || r.o_orderstatus AS order_status_comment,
    CASE 
        WHEN r.o_orderstatus = 'O' THEN 'Order is Open'
        WHEN r.o_orderstatus = 'F' THEN 'Order is Finished'
        ELSE 'Unknown Status'
    END AS detailed_status
FROM RankedOrders r
LEFT JOIN SupplierParts sp ON r.o_orderkey = sp.ps_availqty
LEFT JOIN HighValueCustomers hc ON r.o_orderkey = hc.c_custkey
WHERE r.order_rank <= 10 OR sp.supplier_rank <= 3
ORDER BY r.o_orderdate DESC, r.o_orderkey;
