
WITH supplier_stats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS total_parts_supplied
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY
        s.s_suppkey, s.s_name
),
nation_stats AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        SUM(ss.total_supply_cost) AS national_supply_cost
    FROM
        nation n
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        supplier_stats ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY
        n.n_nationkey, n.n_name
),
region_stats AS (
    SELECT
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS total_nations,
        SUM(ns.national_supply_cost) AS region_supply_cost
    FROM
        region r
    JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN
        nation_stats ns ON n.n_nationkey = ns.n_nationkey
    GROUP BY
        r.r_regionkey, r.r_name
)
SELECT
    r.r_name AS region_name,
    COUNT(DISTINCT n.n_nationkey) AS total_nations,
    SUM(ns.national_supply_cost) AS total_supply_cost,
    AVG(ns.total_suppliers) AS avg_suppliers_per_nation
FROM
    region_stats r
JOIN
    nation_stats ns ON r.r_regionkey = ns.n_nationkey
JOIN
    nation n ON ns.n_nationkey = n.n_nationkey
GROUP BY
    r.r_regionkey, r.r_name
ORDER BY
    total_supply_cost DESC;
