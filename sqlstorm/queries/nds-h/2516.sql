
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
SupplierTotals AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        partsupp ps
    GROUP BY
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
)
SELECT
    p.p_name,
    pt.total_supply_cost,
    co.order_count,
    co.total_spent,
    COALESCE(co.total_spent, 0) / NULLIF(co.order_count, 0) AS avg_spent_per_order,
    RANK() OVER (ORDER BY pt.total_supply_cost DESC) AS supply_cost_rank
FROM
    part p
JOIN SupplierTotals pt ON p.p_partkey = pt.ps_partkey
LEFT JOIN CustomerOrders co ON p.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_suppkey IN (
        SELECT s.s_suppkey 
        FROM supplier s 
        WHERE s.s_nationkey IN (
            SELECT n.n_nationkey 
            FROM nation n 
            WHERE n.n_regionkey = 1
        )
    )
)
WHERE 
    p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) 
        FROM part p2 
        WHERE p2.p_container = 'BOX'
    )
ORDER BY 
    supply_cost_rank, avg_spent_per_order DESC;
