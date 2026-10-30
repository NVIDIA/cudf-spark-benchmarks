WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank_per_nation,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, s.s_nationkey
), CustomerOrders AS (
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
), NationStats AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM
        nation n
    LEFT JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        n.n_nationkey, n.n_name
)

SELECT
    ns.n_name AS nation_name,
    ns.supplier_count,
    ns.total_avail_qty,
    ns.total_supply_cost,
    cs.c_name AS customer_name,
    cs.total_orders,
    cs.total_spent,
    rs.s_name AS top_supplier,
    rs.total_supply_cost AS top_supplier_cost,
    COALESCE(rs.total_available_qty, 0) AS top_supplier_availability
FROM
    NationStats ns
LEFT JOIN
    CustomerOrders cs ON ns.n_nationkey = cs.c_custkey
LEFT JOIN
    RankedSuppliers rs ON ns.n_nationkey = rs.s_nationkey AND rs.rank_per_nation = 1
WHERE
    ns.total_supply_cost > (SELECT AVG(total_supply_cost) FROM NationStats)
ORDER BY
    ns.n_name ASC, cs.total_spent DESC;
