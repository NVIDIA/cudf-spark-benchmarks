WITH RegionSummary AS (
    SELECT
        r.r_name AS region_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM
        region r
    JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY
        r.r_name
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_order_value
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
PartSuppliers AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM
        partsupp ps
    GROUP BY
        ps.ps_partkey
)
SELECT
    rs.region_name,
    rs.nation_count,
    rs.total_supplier_balance,
    co.order_count,
    co.total_order_value,
    ps.total_available_qty,
    ps.avg_supply_cost
FROM
    RegionSummary rs
JOIN
    CustomerOrders co ON rs.nation_count > 5
JOIN
    PartSuppliers ps ON ps.total_available_qty > 100
ORDER BY
    rs.region_name, co.total_order_value DESC;
