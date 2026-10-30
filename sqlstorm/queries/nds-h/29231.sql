WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS distinct_suppliers,
        RANK() OVER (ORDER BY SUM(ps.ps_availqty) DESC) AS avail_qty_rank
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY
        p.p_partkey, p.p_name, p.p_mfgr
),
PopularRegions AS (
    SELECT
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT c.c_custkey) AS total_customers
    FROM
        customer c
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY
        n.n_name, r.r_name
    HAVING
        COUNT(DISTINCT c.c_custkey) > 10
),
FinalResults AS (
    SELECT
        rp.p_name,
        rp.p_mfgr,
        rp.total_avail_qty,
        rp.avg_supply_cost,
        rp.distinct_suppliers,
        pr.region_name,
        pr.total_customers
    FROM
        RankedParts rp
    JOIN
        PopularRegions pr ON pr.region_name IN (
            SELECT DISTINCT r.r_name
            FROM region r
        )
    WHERE
        rp.avail_qty_rank <= 10
)
SELECT
    f.p_name,
    f.p_mfgr,
    f.total_avail_qty,
    f.avg_supply_cost,
    f.distinct_suppliers,
    f.region_name,
    f.total_customers
FROM
    FinalResults f
ORDER BY
    f.total_avail_qty DESC, f.avg_supply_cost ASC;
