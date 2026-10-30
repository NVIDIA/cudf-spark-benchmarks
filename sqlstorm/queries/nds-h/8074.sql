WITH SupplierSummary AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(ps.ps_partkey) AS part_count
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT
        ss.s_suppkey,
        ss.s_name,
        ss.total_supply_cost,
        ss.part_count
    FROM
        SupplierSummary ss
    WHERE
        ss.total_supply_cost > (
            SELECT AVG(total_supply_cost)
            FROM SupplierSummary
        )
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
)
SELECT
    hs.s_name AS supplier_name,
    co.c_name AS customer_name,
    co.order_count,
    co.total_spent,
    hs.part_count
FROM
    HighValueSuppliers hs
JOIN
    CustomerOrders co ON co.total_spent > hs.total_supply_cost
ORDER BY
    hs.total_supply_cost DESC, co.total_spent DESC
LIMIT 10;
