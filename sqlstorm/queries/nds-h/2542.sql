WITH SupplierCosts AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS item_count
    FROM
        orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate <= '1997-12-31'
    GROUP BY
        o.o_orderkey, o.o_custkey
),
CustomerOrderCounts AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS orders_count
    FROM
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT
        sc.s_suppkey,
        sc.s_name,
        sc.total_supply_cost,
        DENSE_RANK() OVER (ORDER BY sc.total_supply_cost DESC) AS cost_rank
    FROM
        SupplierCosts sc
)
SELECT
    co.c_custkey,
    co.c_name,
    COALESCE(os.total_price, 0) AS total_spent,
    COALESCE(tc.orders_count, 0) AS order_count,
    ts.s_name AS top_supplier,
    ts.total_supply_cost
FROM
    customer co
LEFT JOIN OrderSummary os ON co.c_custkey = os.o_custkey
LEFT JOIN CustomerOrderCounts tc ON co.c_custkey = tc.c_custkey
LEFT JOIN TopSuppliers ts ON ts.cost_rank = 1
WHERE
    co.c_acctbal IS NOT NULL AND co.c_acctbal > 0
ORDER BY
    total_spent DESC, order_count DESC, co.c_name ASC;