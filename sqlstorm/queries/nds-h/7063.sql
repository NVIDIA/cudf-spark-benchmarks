WITH CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, SUM(ps.ps_availqty) AS total_available
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_partkey
),
LineItemSummary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY l.l_orderkey
)
SELECT 
    co.c_name, 
    co.order_count, 
    COALESCE(ls.total_revenue, 0) AS total_revenue, 
    sp.total_available
FROM 
    CustomerOrders co
LEFT JOIN 
    LineItemSummary ls ON co.c_custkey = ls.l_orderkey
LEFT JOIN 
    SupplierParts sp ON sp.p_partkey = (SELECT p.p_partkey FROM part p ORDER BY p.p_retailprice DESC LIMIT 1)
WHERE 
    co.total_spent > 1000
ORDER BY 
    co.order_count DESC, co.total_spent DESC;