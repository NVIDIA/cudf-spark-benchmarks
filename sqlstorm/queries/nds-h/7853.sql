WITH SupplyCosts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY
        p.p_partkey, p.p_name, s.s_suppkey
),
HighCostSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(sc.total_supply_cost) AS total_cost
    FROM
        SupplyCosts sc
    JOIN
        supplier s ON sc.s_suppkey = s.s_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
    HAVING
        SUM(sc.total_supply_cost) > (SELECT AVG(total_supply_cost) FROM SupplyCosts)
),
RegionMetrics AS (
    SELECT
        n.n_nationkey,
        r.r_name,
        SUM(oc.o_totalprice) AS total_order_value
    FROM
        orders oc
    JOIN
        customer c ON oc.o_custkey = c.c_custkey
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    WHERE
        oc.o_orderdate >= DATE '1997-01-01'
    GROUP BY
        n.n_nationkey, r.r_name
)
SELECT
    r.r_name,
    r.total_order_value,
    hcs.s_name,
    hcs.total_cost
FROM
    RegionMetrics r
JOIN
    HighCostSuppliers hcs ON r.total_order_value > hcs.total_cost
ORDER BY
    r.total_order_value DESC, hcs.total_cost DESC;