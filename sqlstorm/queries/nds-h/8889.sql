WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_nation
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, n.n_name
),
OrderSummary AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT
        cus.c_custkey,
        cus.c_name,
        cus.total_spent,
        ROW_NUMBER() OVER (ORDER BY cus.total_spent DESC) AS customer_rank
    FROM
        OrderSummary cus
)
SELECT
    r.s_name AS supplier_name,
    r.nation,
    r.total_supply_cost,
    tc.c_name AS top_customer_name,
    tc.total_spent
FROM
    RankedSuppliers r
JOIN
    TopCustomers tc ON r.rank_within_nation = 1
WHERE
    r.total_supply_cost > (SELECT AVG(total_supply_cost) FROM RankedSuppliers)
ORDER BY
    r.nation, r.total_supply_cost DESC, tc.total_spent DESC;
