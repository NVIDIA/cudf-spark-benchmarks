
WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank,
        n.n_regionkey
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_regionkey
),
CustomerOrderStats AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
)
SELECT
    r.r_name AS region,
    COALESCE(suppliers.s_name, 'No Supplier') AS supplier_name,
    suppliers.total_supply_cost,
    customers.c_name AS customer_name,
    customers.total_orders,
    customers.total_spent
FROM
    region r
LEFT JOIN
    RankedSuppliers suppliers ON r.r_regionkey = suppliers.n_regionkey AND suppliers.rank <= 3
LEFT JOIN
    CustomerOrderStats customers ON TRUE
WHERE 
    customers.total_spent > 50000
ORDER BY
    r.r_name, suppliers.total_supply_cost DESC, customers.total_spent DESC;
