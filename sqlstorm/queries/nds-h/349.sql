WITH SupplierPart AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey,
        ps.ps_partkey, 
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_brand,
        p.p_type,
        p.p_retailprice
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
)
SELECT 
    sp.s_name AS supplier_name,
    sp.p_brand,
    sp.p_type,
    AVG(sp.ps_supplycost) AS avg_supply_cost,
    COALESCE(SUM(co.total_lineitem_value), 0) AS total_order_value,
    COUNT(DISTINCT co.o_orderkey) AS total_orders
FROM SupplierPart sp
LEFT JOIN CustomerOrders co ON sp.s_nationkey = co.c_custkey
WHERE sp.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_type = sp.p_type)
GROUP BY sp.s_name, sp.p_brand, sp.p_type
HAVING COUNT(sp.ps_partkey) > 2
ORDER BY avg_supply_cost DESC, total_order_value DESC;
