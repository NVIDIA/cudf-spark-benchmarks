WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.p_partkey,
        sp.p_name,
        (sp.ps_supplycost * sp.ps_availqty) AS total_cost
    FROM SupplierParts sp
    WHERE sp.rank <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01'
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
OrderSummary AS (
    SELECT 
        cust.c_custkey,
        cust.c_name,
        COUNT(ord.o_orderkey) AS order_count,
        COALESCE(SUM(ord.total_spent), 0) AS total_spent
    FROM CustomerOrders ord
    RIGHT JOIN customer cust ON ord.c_custkey = cust.c_custkey
    GROUP BY cust.c_custkey, cust.c_name
)
SELECT 
    os.c_name,
    os.order_count,
    os.total_spent,
    COALESCE(SUM(sp.total_cost), 0) AS total_supply_cost
FROM OrderSummary os
LEFT JOIN TopSuppliers sp ON os.c_custkey = sp.s_suppkey
GROUP BY os.c_name, os.order_count, os.total_spent
ORDER BY os.total_spent DESC, os.order_count DESC;