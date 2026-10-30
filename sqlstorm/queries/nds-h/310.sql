WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= '1996-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING AVG(ps.ps_supplycost) < 100.00
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    d.n_name AS nation_name,
    COALESCE(COUNT(DISTINCT co.c_custkey), 0) AS customer_count,
    COALESCE(SUM(ro.o_totalprice), 0) AS total_order_value,
    COALESCE(SUM(sd.total_available), 0) AS total_supplier_quantity,
    COUNT(DISTINCT sd.s_suppkey) AS unique_suppliers,
    AVG(sd.avg_supply_cost) AS avg_supplier_cost
FROM nation d
LEFT JOIN customerOrders co ON co.c_custkey IS NOT NULL
LEFT JOIN RankedOrders ro ON ro.o_orderkey IS NOT NULL
LEFT JOIN SupplierDetails sd ON sd.total_available IS NOT NULL
WHERE d.n_nationkey IN (
    SELECT n.n_nationkey 
    FROM nation n 
    WHERE n.n_comment LIKE '%friendly%'
)
GROUP BY d.n_name
ORDER BY total_order_value DESC, customer_count DESC;