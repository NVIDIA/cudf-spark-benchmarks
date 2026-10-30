WITH SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY
        s.s_suppkey,
        s.s_name
),
TopSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        ss.total_supply_cost,
        ss.part_count,
        RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS rnk
    FROM
        SupplierStats ss
    JOIN
        supplier s ON ss.s_suppkey = s.s_suppkey
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey
),
TopCustomers AS (
    SELECT
        co.c_custkey,
        co.order_count,
        co.total_spent,
        RANK() OVER (ORDER BY co.total_spent DESC) AS rnk
    FROM
        CustomerOrders co
)
SELECT
    ts.s_name AS supplier_name,
    ts.total_supply_cost,
    tc.total_spent AS customer_spending,
    tc.order_count AS customer_orders,
    tc.rnk AS customer_rank,
    ts.rnk AS supplier_rank
FROM
    TopSuppliers ts
CROSS JOIN
    TopCustomers tc
WHERE
    ts.rnk <= 5 AND tc.rnk <= 5
ORDER BY
    ts.total_supply_cost DESC, tc.total_spent DESC;
