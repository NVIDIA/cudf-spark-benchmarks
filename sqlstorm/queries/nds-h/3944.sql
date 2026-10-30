
WITH SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
OrderDetail AS (
    SELECT
        o.o_orderkey,
        c.c_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= '1996-01-01'
    GROUP BY
        o.o_orderkey, c.c_nationkey
),
RegionNation AS (
    SELECT
        r.r_regionkey,
        r.r_name,
        n.n_nationkey,
        n.n_name
    FROM
        region r
    JOIN
        nation n ON r.r_regionkey = n.n_regionkey
)
SELECT
    rn.r_name AS region_name,
    rn.n_name AS nation_name,
    ss.s_name AS supplier_name,
    ss.total_avail_qty,
    ss.total_supply_cost,
    ss.avg_acctbal,
    COUNT(od.total_order_value) AS order_count,
    COALESCE(SUM(od.total_order_value), 0) AS total_order_value_sum
FROM
    SupplierStats ss
LEFT OUTER JOIN
    OrderDetail od ON ss.s_suppkey IN (SELECT DISTINCT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey
        FROM part p WHERE p.p_retailprice > 100))
JOIN
    RegionNation rn ON ss.s_suppkey = rn.n_nationkey
GROUP BY
    rn.r_name, rn.n_name, ss.s_name, ss.total_avail_qty, ss.total_supply_cost, ss.avg_acctbal
HAVING
    SUM(od.total_order_value) IS NOT NULL
ORDER BY
    region_name, nation_name, total_order_value_sum DESC
LIMIT 100;
