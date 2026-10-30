WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY pn.p_mfgr ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part pn ON ps.ps_partkey = pn.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS orders_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighSpenders AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_spent,
        co.orders_count,
        co.last_order_date
    FROM CustomerOrders co
    WHERE co.total_spent > 10000
)
SELECT 
    hs.c_custkey,
    hs.c_name,
    hs.total_spent,
    hs.orders_count,
    hs.last_order_date,
    rs.s_name AS top_supplier,
    rs.rank
FROM HighSpenders hs
JOIN RankedSuppliers rs ON rs.rank = 1
ORDER BY hs.total_spent DESC, rs.s_name ASC;
