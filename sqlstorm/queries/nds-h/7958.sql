
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
CustomerSegment AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_mktsegment
),
FlaggedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        l.l_orderkey,
        l.l_returnflag,
        l.l_linestatus,
        l.l_discount,
        l.l_extendedprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'R' AND l.l_linestatus = 'O'
)
SELECT 
    rs.nation_name,
    rs.s_name,
    cs.c_mktsegment,
    SUM(cs.total_spent) AS total_customer_spent,
    COUNT(fo.o_orderkey) AS flagged_orders_count
FROM RankedSuppliers rs
JOIN CustomerSegment cs ON rs.nation_name = cs.c_mktsegment
LEFT JOIN FlaggedOrders fo ON fo.o_orderkey = cs.c_custkey
WHERE rs.rank <= 5
GROUP BY rs.nation_name, rs.s_name, cs.c_mktsegment
ORDER BY total_customer_spent DESC, flagged_orders_count DESC;
