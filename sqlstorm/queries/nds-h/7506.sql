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
        r.r_regionkey, r.r_name
),
PartSupplierStats AS (
    SELECT
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM
        partsupp ps
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    WHERE
        p.p_retailprice > 100.00
    GROUP BY
        ps.ps_partkey, ps.ps_suppkey
)
SELECT
    rs.region_name,
    rs.nation_count,
    rs.total_supplier_balance,
    ps.total_avail_qty,
    ps.avg_supply_cost
FROM
    RegionSummary rs
LEFT JOIN
    PartSupplierStats ps ON ps.ps_partkey IN (
        SELECT p_partkey
        FROM part
        WHERE p_size >= 10
    )
ORDER BY
    rs.region_name ASC, ps.avg_supply_cost DESC
LIMIT 50;
